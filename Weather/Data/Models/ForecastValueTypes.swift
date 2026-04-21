import Foundation

struct MapCoordinate: Sendable, Hashable {
    var latitude: Double
    var longitude: Double
}

struct IANATimeZone: Sendable, Hashable {
    var identifier: String
}

struct PlaceSearchQuery: Sendable {
    var rawText: String

    var normalized: String {
        rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValidForRemoteSearch: Bool {
        normalized.count >= 2
    }
}
