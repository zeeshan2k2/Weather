//
//  APIManager.swift
//  Weather
//

import Foundation

/// Shared HTTP client: `URLSession`, status handling, optional JSON decode. Endpoints and DTOs live outside this type.
enum APIManager {

    /// Avoids `waitsForConnectivity` (default `true` on many OS versions), which can sit ~1–2s after Wi‑Fi/cellular toggles before firing.
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 45
        return URLSession(configuration: config)
    }()

    /// Typical connectivity / reachability failures (for offline-style UI).
    static func isLikelyConnectivityFailure(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost,
             .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff, .timedOut:
            return true
        default:
            return false
        }
    }

    /// GET; returns body on HTTP 2xx, otherwise `URLError(.badServerResponse)`.
    static func get(url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    /// GET + JSON decode on success.
    static func fetchDecodable<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let data = try await get(url: url)
        return try decoder.decode(T.self, from: data)
    }
}
