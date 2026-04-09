//
//  ForecastRepository.swift
//  Weather
//

import Foundation

/// Loads forecast + place search data for the UI layer.
protocol ForecastRepository: Sendable {
    func fetchForecast(coordinate: MapCoordinate, timeZone: IANATimeZone) async throws -> WeatherForecast
    func searchPlaces(query: PlaceSearchQuery) async throws -> [WeatherPlace]
}

// MARK: - Remote implementation

struct RemoteForecastRepository: ForecastRepository {

    func fetchForecast(coordinate: MapCoordinate, timeZone: IANATimeZone) async throws -> WeatherForecast {
        let url = ForecastRemoteEndpoints.forecastURL(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timeZoneIdentifier: timeZone.identifier
        )
        let dto = try await APIManager.fetchDecodable(ForecastResponseDTO.self, from: url)
        return try dto.toWeatherForecast(timeZoneIdentifier: timeZone.identifier)
    }

    func searchPlaces(query: PlaceSearchQuery) async throws -> [WeatherPlace] {
        guard query.isValidForRemoteSearch else { return [] }
        guard let url = ForecastRemoteEndpoints.placeSearchURL(name: query.normalized) else {
            throw URLError(.badURL)
        }
        let dto = try await APIManager.fetchDecodable(PlaceSearchResponseDTO.self, from: url)
        return (dto.results ?? []).map(WeatherPlace.init(dto:))
    }
}

// MARK: - Remote API URLs

private enum ForecastRemoteEndpoints {

    private static let forecastBase = URL(string: "https://api.open-meteo.com/v1/forecast")!
    private static let placeSearchBase = URL(string: "https://geocoding-api.open-meteo.com/v1/search")!

    static func forecastURL(latitude: Double, longitude: Double, timeZoneIdentifier: String) -> URL {
        var components = URLComponents(url: forecastBase, resolvingAgainstBaseURL: false)!
        let current = [
            "temperature_2m", "apparent_temperature", "relative_humidity_2m",
            "weather_code", "is_day", "precipitation",
            "wind_speed_10m"
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

    static func placeSearchURL(name query: String) -> URL? {
        var components = URLComponents(url: placeSearchBase, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        return components.url
    }
}
