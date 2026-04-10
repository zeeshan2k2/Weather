
import Foundation

struct WeatherForecast: Sendable {
    let currentTempF: Int
    let currentCode: Int
    let currentIsDay: Bool
    let apparentTempF: Int?
    let relativeHumidityPercent: Int?
    let precipitationMm: Double?
    let windSpeedMph: Double?
    let daily: [DailyForecastItem]
    let hourly: [HourlyForecastItem]
}

struct DailyForecastItem: Sendable {
    let id: String
    let weekdayAbbrev: String
    let weatherCode: Int
    let highTempF: Int
    let lowTempF: Int
    let precipitationProbabilityMax: Int?
    let sunrise: String?
    let sunset: String?
}

struct HourlyForecastItem: Sendable, Identifiable {
    var id: String { timeISO }
    let timeISO: String
    let tempF: Int
    let weatherCode: Int
    let precipitationProbabilityPercent: Int?
}

/// A searchable location used for forecast requests (backed by remote place-search JSON).
struct WeatherPlace: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?
    let timezone: String

    var displayLine: String {
        if let admin1, !admin1.isEmpty, admin1 != name {
            return "\(name), \(admin1), \(country)"
        }
        return "\(name), \(country)"
    }
}
