//
//  WeatherService.swift
//  Weather
//
//  Fetches forecast from Open-Meteo (free, no API key).
//

import Foundation

enum WeatherService {

    private static let cupertinoForecastURL = URL(string:
        "https://api.open-meteo.com/v1/forecast?latitude=37.3230&longitude=-122.0322"
        + "&current=temperature_2m,weather_code,is_day"
        + "&daily=weather_code,temperature_2m_max"
        + "&temperature_unit=fahrenheit&timezone=America%2FLos_Angeles&forecast_days=5")!

    /// Current conditions plus daily highs for the next few days.
    static func fetchCupertinoForecast() async throws -> CupertinoForecast {
        let (data, response) = try await URLSession.shared.data(from: cupertinoForecastURL)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return try decoded.makeForecast()
    }

    /// Maps WMO weather codes (Open-Meteo) to SF Symbols.
    static func symbolName(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55:
            return "cloud.drizzle.fill"
        case 61, 63, 65:
            return "cloud.rain.fill"
        case 66, 67:
            return "cloud.sleet.fill"
        case 71, 73, 75, 77:
            return "cloud.snow.fill"
        case 80, 81, 82:
            return "cloud.heavyrain.fill"
        case 85, 86:
            return "cloud.snow.fill"
        case 95:
            return "cloud.bolt.fill"
        case 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }
}

// MARK: - Public model

struct CupertinoForecast: Sendable {
    let currentTempF: Int
    let currentCode: Int
    let currentIsDay: Bool
    let daily: [DailyForecastItem]
}

struct DailyForecastItem: Sendable {
    let id: String
    let weekdayAbbrev: String
    let weatherCode: Int
    let highTempF: Int
}

// MARK: - API decoding

private struct OpenMeteoResponse: Decodable {
    let current: CurrentDTO
    let daily: DailyDTO

    func makeForecast() throws -> CupertinoForecast {
        let items = try daily.makeItems()
        return CupertinoForecast(
            currentTempF: Int(current.temperature2m.rounded()),
            currentCode: current.weatherCode,
            currentIsDay: current.isDay == 1,
            daily: items
        )
    }
}

private struct CurrentDTO: Decodable {
    let temperature2m: Double
    let weatherCode: Int
    let isDay: Int

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case isDay = "is_day"
    }
}

private struct DailyDTO: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
    }

    func makeItems() throws -> [DailyForecastItem] {
        guard time.count == weatherCode.count, time.count == temperature2mMax.count, !time.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        return (0 ..< time.count).map { i in
            DailyForecastItem(
                id: time[i],
                weekdayAbbrev: Self.weekdayAbbrev(from: time[i]),
                weatherCode: weatherCode[i],
                highTempF: Int(temperature2mMax[i].rounded())
            )
        }
    }

    private static func weekdayAbbrev(from dateString: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: "America/Los_Angeles")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dateString) else { return "---" }
        parser.dateFormat = "EEE"
        return parser.string(from: date).uppercased()
    }
}
