//
//  WeatherService.swift
//  Weather
//
//  Fetches forecast from Open-Meteo (free, no API key).
//

import Foundation

enum WeatherService {

    /// Current conditions, daily outlook, and hourly series.
    static func fetchForecast(latitude: Double, longitude: Double, timeZoneIdentifier: String) async throws -> WeatherForecast {
        let url = forecastURL(latitude: latitude, longitude: longitude, timeZoneIdentifier: timeZoneIdentifier)
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return try decoded.makeForecast(timeZoneIdentifier: timeZoneIdentifier)
    }

    /// Open-Meteo geocoding: search cities / places by name.
    static func searchPlaces(name query: String) async throws -> [GeocodingPlace] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(GeocodingResponseDTO.self, from: data)
        return (decoded.results ?? []).map(GeocodingPlace.init(dto:))
    }

    private static func forecastURL(latitude: Double, longitude: Double, timeZoneIdentifier: String) -> URL {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        let current = [
            "temperature_2m", "apparent_temperature", "relative_humidity_2m",
            "weather_code", "is_day", "precipitation",
            "wind_speed_10m", "wind_direction_10m"
        ].joined(separator: ",")
        let daily = [
            "weather_code", "temperature_2m_max", "temperature_2m_min",
            "precipitation_probability_max", "sunrise", "sunset"
        ].joined(separator: ",")
        let hourly = [
            "temperature_2m", "weather_code", "precipitation_probability"
        ].joined(separator: ",")
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: current),
            URLQueryItem(name: "daily", value: daily),
            URLQueryItem(name: "hourly", value: hourly),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "timezone", value: timeZoneIdentifier),
            URLQueryItem(name: "forecast_days", value: "5")
        ]
        return components.url!
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

    /// Short condition label for UI (WMO codes used by Open-Meteo).
    static func conditionDescription(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0:
            return isDay ? "Sunny" : "Clear"
        case 1:
            return "Mostly clear"
        case 2:
            return "Partly cloudy"
        case 3:
            return "Overcast"
        case 45, 48:
            return "Fog"
        case 51, 53, 55:
            return "Drizzle"
        case 61:
            return "Light rain"
        case 63:
            return "Rain"
        case 65:
            return "Heavy rain"
        case 66, 67:
            return "Freezing rain"
        case 71, 73, 75:
            return "Snow"
        case 77:
            return "Snow grains"
        case 80, 81, 82:
            return "Rain showers"
        case 85, 86:
            return "Snow showers"
        case 95:
            return "Thunderstorm"
        case 96, 99:
            return "Thunderstorm & hail"
        default:
            return "Weather"
        }
    }
}

// MARK: - Public models

struct WeatherForecast: Sendable {
    let currentTempF: Int
    let currentCode: Int
    let currentIsDay: Bool
    let apparentTempF: Int?
    let relativeHumidityPercent: Int?
    let precipitationMm: Double?
    let windSpeedMph: Double?
    let windDirectionDegrees: Int?
    let daily: [DailyForecastItem]
    let hourly: [HourlyForecastItem]
}

struct DailyForecastItem: Sendable {
    let id: String
    let weekdayAbbrev: String
    let weatherCode: Int
    let highTempF: Int
    let lowTempF: Int
    /// Max probability of precipitation for the day (0–100), if provided.
    let precipitationProbabilityMax: Int?
    /// Local date-time strings from the API, e.g. `2026-04-08T06:42`.
    let sunrise: String?
    let sunset: String?
}

struct HourlyForecastItem: Sendable, Identifiable {
    /// ISO-like local time from the API, e.g. `2026-04-07T14:00`.
    var id: String { timeISO }
    let timeISO: String
    let tempF: Int
    let weatherCode: Int
    let precipitationProbabilityPercent: Int?
}

struct GeocodingPlace: Identifiable, Hashable, Sendable {
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

    fileprivate init(dto: GeocodeResultDTO) {
        id = dto.id
        name = dto.name
        latitude = dto.latitude
        longitude = dto.longitude
        country = dto.country
        admin1 = dto.admin1
        timezone = dto.timezone
    }
}

// MARK: - Geocoding API

private struct GeocodingResponseDTO: Decodable {
    let results: [GeocodeResultDTO]?
}

private struct GeocodeResultDTO: Decodable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?
    let timezone: String
}

// MARK: - Forecast API decoding

private struct OpenMeteoResponse: Decodable {
    let current: CurrentDTO
    let daily: DailyDTO
    let hourly: HourlyDTO

    func makeForecast(timeZoneIdentifier: String) throws -> WeatherForecast {
        let dailyItems = try daily.makeItems(timeZoneIdentifier: timeZoneIdentifier)
        let hourlyItems = try hourly.makeItems()
        return WeatherForecast(
            currentTempF: Int(current.temperature2m.rounded()),
            currentCode: current.weatherCode,
            currentIsDay: current.isDay == 1,
            apparentTempF: current.apparentTemperature.map { Int($0.rounded()) },
            relativeHumidityPercent: current.relativeHumidity2m,
            precipitationMm: current.precipitation,
            windSpeedMph: current.windSpeed10m,
            windDirectionDegrees: current.windDirection10m,
            daily: dailyItems,
            hourly: hourlyItems
        )
    }
}

private struct CurrentDTO: Decodable {
    let temperature2m: Double
    let apparentTemperature: Double?
    let relativeHumidity2m: Int?
    let weatherCode: Int
    let isDay: Int
    let precipitation: Double?
    let windSpeed10m: Double?
    let windDirection10m: Int?

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case relativeHumidity2m = "relative_humidity_2m"
        case weatherCode = "weather_code"
        case isDay = "is_day"
        case precipitation
        case windSpeed10m = "wind_speed_10m"
        case windDirection10m = "wind_direction_10m"
    }
}

private struct DailyDTO: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationProbabilityMax: [Int]?
    let sunrise: [String]
    let sunset: [String]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case sunrise
        case sunset
    }

    func makeItems(timeZoneIdentifier: String) throws -> [DailyForecastItem] {
        let n = time.count
        guard n == weatherCode.count,
              n == temperature2mMax.count,
              n == temperature2mMin.count,
              n == sunrise.count,
              n == sunset.count,
              n > 0 else {
            throw URLError(.cannotParseResponse)
        }
        let precip = precipitationProbabilityMax
        if let precip, precip.count != n {
            throw URLError(.cannotParseResponse)
        }
        return (0 ..< n).map { i in
            DailyForecastItem(
                id: time[i],
                weekdayAbbrev: Self.weekdayAbbrev(from: time[i], timeZoneIdentifier: timeZoneIdentifier),
                weatherCode: weatherCode[i],
                highTempF: Int(temperature2mMax[i].rounded()),
                lowTempF: Int(temperature2mMin[i].rounded()),
                precipitationProbabilityMax: precip?[i],
                sunrise: sunrise[i],
                sunset: sunset[i]
            )
        }
    }

    private static func weekdayAbbrev(from dateString: String, timeZoneIdentifier: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dateString) else { return "---" }
        parser.dateFormat = "EEE"
        return parser.string(from: date).uppercased()
    }
}

private struct HourlyDTO: Decodable {
    let time: [String]
    let temperature2m: [Double]
    let weatherCode: [Int]
    let precipitationProbability: [Int]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case precipitationProbability = "precipitation_probability"
    }

    func makeItems() throws -> [HourlyForecastItem] {
        let n = time.count
        guard n == temperature2m.count, n == weatherCode.count, n > 0 else {
            throw URLError(.cannotParseResponse)
        }
        let precip = precipitationProbability
        if let precip, precip.count != n {
            throw URLError(.cannotParseResponse)
        }
        return (0 ..< n).map { i in
            HourlyForecastItem(
                timeISO: time[i],
                tempF: Int(temperature2m[i].rounded()),
                weatherCode: weatherCode[i],
                precipitationProbabilityPercent: precip?[i]
            )
        }
    }
}
