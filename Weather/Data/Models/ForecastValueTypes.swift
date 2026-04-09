//
//  ForecastValueTypes.swift
//  Weather
//

import Foundation

/// Geographic point for forecast requests (Open‑Meteo uses WGS84).
struct MapCoordinate: Sendable, Hashable {
    var latitude: Double
    var longitude: Double
}

/// IANA timezone identifier, e.g. `America/Los_Angeles`.
struct IANATimeZone: Sendable, Hashable {
    var identifier: String
}

/// Raw user text for city / place search; normalization lives on the type.
struct PlaceSearchQuery: Sendable {
    var rawText: String

    var normalized: String {
        rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValidForRemoteSearch: Bool {
        normalized.count >= 2
    }
}
