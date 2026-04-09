//
//  WeatherDashboardModel.swift
//  Weather
//
//  Forecast load state + mapping; location persistence stays in the view (`@AppStorage`).
//

import Combine
import Foundation

enum DashboardTemperature {
    static func display(fahrenheit: Int, useCelsius: Bool) -> Int {
        useCelsius ? Int((Double(fahrenheit) - 32) * 5 / 9) : fahrenheit
    }

    /// Current remote `precipitation` is often the last hour (near 0 when dry). When negligible, show today’s max chance from daily.
    static func precipitationTileValue(mm: Double?, todayChancePercent: Int?) -> String {
        if let mm, mm >= 0.02 {
            if mm < 1 { return String(format: "%.1f mm", mm) }
            return String(format: "%.0f mm", mm)
        }
        if let chance = todayChancePercent {
            return "\(chance)%"
        }
        if let mm, mm >= 0, mm < 0.02 {
            return "None"
        }
        return "—"
    }
}

final class WeatherDashboardModel: ObservableObject {
    private let forecastRepository: any ForecastRepository

    @Published var weatherData: [WeatherDay] = []
    @Published var currentTemp = 72
    @Published var currentWeatherCode = 0
    @Published var currentIsDay = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hourlyForecast: [HourlyForecastItem] = []
    @Published var apparentTempF: Int?
    @Published var humidityPercent: Int?
    @Published var precipitationMm: Double?
    @Published var windSpeedMph: Double?
    @Published var lastUpdatedAt: Date?
    @Published var loadFailedOffline = false
    @Published var pendingManualRetryProgress = false

    init(forecastRepository: any ForecastRepository = RemoteForecastRepository()) {
        self.forecastRepository = forecastRepository
    }

    var mainHeroSymbol: String {
        WeatherPresentation.symbolName(for: currentWeatherCode, isDay: currentIsDay)
    }

    var hourlySlice24: [HourlyForecastItem] {
        Array(hourlyForecast.prefix(24))
    }

    var lastUpdatedLabel: String? {
        guard let lastUpdatedAt else { return nil }
        return "Last updated \(lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))"
    }

    var showLoadFailurePlaceholder: Bool {
        errorMessage != nil && weatherData.isEmpty && !isLoading
    }

    func hourlyItems(forDayId dayId: String) -> [HourlyForecastItem] {
        hourlyForecast.filter { $0.timeISO.hasPrefix(dayId) }
    }

    func loadForecast(isManualRetry: Bool, latitude: Double, longitude: Double, timeZoneIdentifier: String) async {
        if !isManualRetry {
            errorMessage = nil
        }
        isLoading = true
        defer {
            isLoading = false
            pendingManualRetryProgress = false
        }
        do {
            let forecast = try await forecastRepository.fetchForecast(
                coordinate: MapCoordinate(latitude: latitude, longitude: longitude),
                timeZone: IANATimeZone(identifier: timeZoneIdentifier)
            )
            currentTemp = forecast.currentTempF
            currentWeatherCode = forecast.currentCode
            currentIsDay = forecast.currentIsDay
            apparentTempF = forecast.apparentTempF
            humidityPercent = forecast.relativeHumidityPercent
            precipitationMm = forecast.precipitationMm
            windSpeedMph = forecast.windSpeedMph
            hourlyForecast = forecast.hourly
            weatherData = forecast.daily.map { item in
                WeatherDay(
                    id: item.id,
                    dayOfWeek: item.weekdayAbbrev,
                    imageName: WeatherPresentation.symbolName(for: item.weatherCode, isDay: true),
                    weatherCode: item.weatherCode,
                    temperature: item.highTempF,
                    lowTempF: item.lowTempF,
                    precipitationProbabilityMax: item.precipitationProbabilityMax,
                    sunrise: item.sunrise,
                    sunset: item.sunset
                )
            }
            lastUpdatedAt = Date()
            loadFailedOffline = false
            errorMessage = nil
        } catch {
            if error is CancellationError { return }
            if (error as? URLError)?.code == .cancelled { return }
            let offline = WeatherPresentation.isLikelyConnectivityFailure(error)
            loadFailedOffline = offline
            errorMessage = offline
                ? "No internet connection."
                : "Couldn’t load weather. Check your connection and try again."
        }
    }
}
