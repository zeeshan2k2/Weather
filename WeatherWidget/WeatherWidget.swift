import SwiftUI
import WidgetKit

struct WidgetHourlySlot: Sendable {
    let hourLabel: String
    let tempF: Int
    let symbolName: String
}

struct WeatherWidgetEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let temperatureF: Int
    /// Today’s high / low (°F) from the first daily bucket; `nil` when unavailable (e.g. errors).
    let dailyHighTempF: Int?
    let dailyLowTempF: Int?
    /// Medium widget: hourly strip under the city line, above the condition (left column only).
    let hourlySlots: [WidgetHourlySlot]
    /// Saved location coordinates (bottom-right of medium layout); `nil` when unavailable.
    let latitude: Double?
    let longitude: Double?
    let conditionText: String
    let symbolName: String
    let weatherCode: Int
    let isDay: Bool
    let isPlaceholder: Bool
    let errorMessage: String?
}

private extension WeatherWidgetEntry {
    var highLowPair: (high: Int, low: Int)? {
        guard let h = dailyHighTempF, let l = dailyLowTempF else { return nil }
        return (h, l)
    }
}

struct WeatherTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> WeatherWidgetEntry {
        WeatherWidgetEntry(
            date: Date(),
            cityName: "Cupertino, CA",
            temperatureF: 72,
            dailyHighTempF: 78,
            dailyLowTempF: 62,
            hourlySlots: [
                WidgetHourlySlot(hourLabel: "2 PM", tempF: 74, symbolName: "sun.max.fill"),
                WidgetHourlySlot(hourLabel: "3 PM", tempF: 75, symbolName: "sun.max.fill"),
                WidgetHourlySlot(hourLabel: "4 PM", tempF: 73, symbolName: "cloud.sun.fill"),
                WidgetHourlySlot(hourLabel: "5 PM", tempF: 72, symbolName: "cloud.fill"),
                WidgetHourlySlot(hourLabel: "6 PM", tempF: 71, symbolName: "cloud.fill")
            ],
            latitude: 37.3230,
            longitude: -122.0322,
            conditionText: "Sunny",
            symbolName: "sun.max.fill",
            weatherCode: 0,
            isDay: true,
            isPlaceholder: true,
            errorMessage: nil
        )
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
        let city = defaults.string(forKey: AppGroupWeatherDefaults.Key.cityName) ?? "Cupertino, CA"
        let latString = defaults.string(forKey: AppGroupWeatherDefaults.Key.latitude) ?? "37.3230"
        let lonString = defaults.string(forKey: AppGroupWeatherDefaults.Key.longitude) ?? "-122.0322"
        let tz = defaults.string(forKey: AppGroupWeatherDefaults.Key.timezone) ?? "America/Los_Angeles"

        guard let lat = Double(latString), let lon = Double(lonString) else {
            return WeatherWidgetEntry(
                date: Date(),
                cityName: city,
                temperatureF: 0,
                dailyHighTempF: nil,
                dailyLowTempF: nil,
                hourlySlots: [],
                latitude: nil,
                longitude: nil,
                conditionText: "",
                symbolName: "exclamationmark.triangle.fill",
                weatherCode: 3,
                isDay: false,
                isPlaceholder: false,
                errorMessage: "Invalid location"
            )
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
            return WeatherWidgetEntry(
                date: Date(),
                cityName: city,
                temperatureF: forecast.currentTempF,
                dailyHighTempF: today?.highTempF,
                dailyLowTempF: today?.lowTempF,
                hourlySlots: hourly,
                latitude: lat,
                longitude: lon,
                conditionText: condition,
                symbolName: symbol,
                weatherCode: forecast.currentCode,
                isDay: forecast.currentIsDay,
                isPlaceholder: false,
                errorMessage: nil
            )
        } catch {
            let message = WeatherPresentation.isLikelyConnectivityFailure(error)
                ? "Offline"
                : "Couldn’t load"
            return WeatherWidgetEntry(
                date: Date(),
                cityName: city,
                temperatureF: 0,
                dailyHighTempF: nil,
                dailyLowTempF: nil,
                hourlySlots: [],
                latitude: lat,
                longitude: lon,
                conditionText: "",
                symbolName: "wifi.slash",
                weatherCode: 3,
                isDay: false,
                isPlaceholder: false,
                errorMessage: message
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
        let start = pairs.firstIndex(where: { $0.1 >= now }) ?? 0
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

struct WeatherForecastWidget: Widget {
    let kind: String = "WeatherForecastWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("Current conditions for your saved location.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct WeatherWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var widgetMargins
    var entry: WeatherWidgetEntry

    private var basePalette: [Color] {
        WeatherSkyStyle.gradientColors(
            weatherCode: entry.weatherCode,
            isDay: entry.isDay,
            tempFahrenheit: max(entry.temperatureF, 32)
        )
    }

    /// Matches app `BackgroundView`: same vertical gradient, plus a light top wash so the widget still has depth.
    private var widgetAtmosphereBackground: some View {
        ZStack {
            LinearGradient(
                colors: basePalette,
                startPoint: .top,
                endPoint: .bottom
            )
            LinearGradient(
                colors: [Color.white.opacity(entry.isDay ? 0.12 : 0.06), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.45)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var body: some View {
        Group {
            if let error = entry.errorMessage {
                errorLayout(message: error)
            } else if family == .systemMedium {
                mediumWeatherLayout
            } else {
                smallWeatherLayout
            }
        }
        .padding(widgetMargins)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            widgetAtmosphereBackground
        }
    }

    private var smallWeatherLayout: some View {
        HStack(alignment: .top, spacing: 4) {
            ZStack(alignment: .bottomLeading) {
                // Watermark: monochrome only (matches request — no multicolor on the large glyph).
                Image(systemName: entry.symbolName)
                    .font(.system(size: 72, weight: .ultraLight))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.white.opacity(0.16))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .offset(x: 10, y: 4)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.cityName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(4)
                        .minimumScaleFactor(0.78)
                        .shadow(color: .black.opacity(0.22), radius: 2, y: 1)

                    Spacer(minLength: 8)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            // Same rounded / medium “hero” weight family as `MainWeatherView` (scaled for widget).
                            Text("\(entry.temperatureF)°")
                                .font(.system(size: 38, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.85)
                                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                            foregroundWeatherIcon(font: .system(size: 24, weight: .regular))
                        }
                        Text(entry.conditionText)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.95))
                            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)

            if let highLow = entry.highLowPair {
                dailyHighLowColumn(high: highLow.high, low: highLow.low, compact: true)
            }
        }
    }

    private var mediumWeatherLayout: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.cityName)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .shadow(color: .black.opacity(0.22), radius: 2, y: 1)

                if !entry.hourlySlots.isEmpty {
                    mediumLeftHourlyStrip
                        .padding(.top, 8)
                }

                Spacer(minLength: 0)

                Text(entry.conditionText)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 0) {
                VStack(alignment: .trailing, spacing: 4) {
                    foregroundWeatherIcon(font: .system(size: 44, weight: .regular))
                        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                    Text("\(entry.temperatureF)°")
                        .font(.system(size: 54, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.8)
                        .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                }

                Spacer(minLength: 0)

                mediumRightBottomMeta
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Bottom-right: daily H/L (when known), then latitude / longitude — trailing, small type.
    @ViewBuilder
    private var mediumRightBottomMeta: some View {
        if entry.highLowPair != nil || (entry.latitude != nil && entry.longitude != nil) {
            VStack(alignment: .trailing, spacing: 2) {
                if let highLow = entry.highLowPair {
                    Text("H \(highLow.high)°  L \(highLow.low)°")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                        .monospacedDigit()
                        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                }
                if let lat = entry.latitude, let lon = entry.longitude {
                    Text(String(format: "%.2f°, %.2f°", lat, lon))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityCoordinateLabel)
        }
    }

    private var accessibilityCoordinateLabel: String {
        var parts: [String] = []
        if let h = entry.dailyHighTempF, let l = entry.dailyLowTempF {
            parts.append("High \(h) degrees, low \(l) degrees")
        }
        if let lat = entry.latitude, let lon = entry.longitude {
            parts.append("Latitude \(lat), longitude \(lon)")
        }
        return parts.joined(separator: ". ")
    }

    /// Left column only: under city / country, above condition; five hour columns from the leading edge.
    private var mediumLeftHourlyStrip: some View {
        let slots = Array(entry.hourlySlots.prefix(5))
        return HStack(alignment: .center, spacing: 3) {
            ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                VStack(alignment: .leading, spacing: 3) {
                    Text(slot.hourLabel)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                        .frame(minWidth: 36, alignment: .leading)
                    multicolorSymbol(slot.symbolName, font: .system(size: 18, weight: .regular))
                    Text("\(slot.tempF)°")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.95))
                }
                .frame(minWidth: 36, alignment: .leading)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next five hours")
    }

    private func dailyHighLowColumn(high: Int, low: Int, compact: Bool) -> some View {
        // Smaller than main temp so the column reads as secondary (high / low for today).
        let labelSize: CGFloat = compact ? 7 : 8
        let valueSize: CGFloat = compact ? 11 : 13
        return VStack(alignment: .trailing, spacing: 0) {
            Text("H")
                .font(.system(size: labelSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
            Text("\(high)°")
                .font(.system(size: valueSize, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
            Text("L")
                .font(.system(size: labelSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.top, 2)
            Text("\(low)°")
                .font(.system(size: valueSize, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("High \(high) degrees, low \(low) degrees")
    }

    private func foregroundWeatherIcon(font: Font) -> some View {
        multicolorSymbol(entry.symbolName, font: font)
    }

    @ViewBuilder
    private func multicolorSymbol(_ systemName: String, font: Font) -> some View {
        if #available(iOSApplicationExtension 18.0, *) {
            Image(systemName: systemName)
                .widgetAccentedRenderingMode(.fullColor)
                .font(font)
                .symbolRenderingMode(.multicolor)
        } else {
            Image(systemName: systemName)
                .font(font)
                .symbolRenderingMode(.multicolor)
        }
    }

    private func errorLayout(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.cityName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(3)
            HStack(spacing: 8) {
                foregroundWeatherIcon(font: .body)
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
