import Foundation
import WidgetKit

struct WeatherTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> WeatherWidgetEntry {
        WeatherWidgetEntry.placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherWidgetEntry) -> Void) {
        Task {
            completion(await Self.loadEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherWidgetEntry>) -> Void) {
        Task {
            let entry = await Self.loadEntry()
            let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private static func loadEntry() async -> WeatherWidgetEntry {
        let defaults = AppGroupWeatherDefaults.shared
        let useCelsius = defaults.bool(forKey: AppGroupWeatherDefaults.Key.useCelsius)
        guard
            let city = defaults.string(forKey: AppGroupWeatherDefaults.Key.cityName),
            !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let latString = defaults.string(forKey: AppGroupWeatherDefaults.Key.latitude),
            let lonString = defaults.string(forKey: AppGroupWeatherDefaults.Key.longitude),
            let tz = defaults.string(forKey: AppGroupWeatherDefaults.Key.timezone),
            !tz.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            TimeZone(identifier: tz) != nil,
            let lat = Double(latString),
            let lon = Double(lonString),
            lat.isFinite, lon.isFinite
        else {
            return WeatherWidgetEntry.invalidLocation(cityName: "Weather", useCelsius: useCelsius)
        }

        do {
            let repo = RemoteForecastRepository()
            let forecast = try await repo.fetchForecast(
                coordinate: MapCoordinate(latitude: lat, longitude: lon),
                timeZone: IANATimeZone(identifier: tz)
            )
            let condition = WeatherPresentation.conditionDescription(
                for: forecast.currentCode,
                isDay: forecast.currentIsDay
            )
            let symbol = WeatherPresentation.symbolName(for: forecast.currentCode, isDay: forecast.currentIsDay)
            let today = forecast.daily.first
            let hourly = Self.buildHourlySlots(from: forecast, timeZoneIdentifier: tz, limit: 5)
            return WeatherWidgetEntry.success(
                cityName: city,
                useCelsius: useCelsius,
                temperatureF: forecast.currentTempF,
                dailyHighTempF: today?.highTempF,
                dailyLowTempF: today?.lowTempF,
                hourlySlots: hourly,
                latitude: lat,
                longitude: lon,
                conditionText: condition,
                symbolName: symbol,
                weatherCode: forecast.currentCode,
                isDay: forecast.currentIsDay
            )
        } catch {
            let message = WeatherPresentation.isLikelyConnectivityFailure(error)
                ? "Offline"
                : "Couldn’t load"
            return WeatherWidgetEntry.failure(
                cityName: city,
                useCelsius: useCelsius,
                latitude: lat,
                longitude: lon,
                message: message
            )
        }
    }

    private static func buildHourlySlots(from forecast: WeatherForecast, timeZoneIdentifier: String, limit: Int) -> [WidgetHourlySlot] {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let pairs: [(HourlyForecastItem, Date)] = forecast.hourly.compactMap { h in
            guard let d = fmt.date(from: h.timeISO) else { return nil }
            return (h, d)
        }
        guard !pairs.isEmpty else { return [] }

        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        let cutoff = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let start = pairs.firstIndex(where: { $0.1 >= cutoff }) ?? 0
        let end = min(start + limit, pairs.count)
        guard start < end else { return [] }

        return pairs[start ..< end].map { item, _ in
            let label = WeatherDateFormatting.formattedHourLabel(timeISO: item.timeISO, timeZoneIdentifier: timeZoneIdentifier)
            let isDay = WeatherDateFormatting.hourlyIsDaylight(
                timeISO: item.timeISO,
                timeZoneIdentifier: timeZoneIdentifier,
                fallbackIsDay: true
            )
            let sym = WeatherPresentation.symbolName(for: item.weatherCode, isDay: isDay)
            return WidgetHourlySlot(hourLabel: label, tempF: item.tempF, symbolName: sym)
        }
    }
}
