import Foundation

struct SavedWeatherPlace: Codable, Equatable, Identifiable, Hashable, Sendable {
    let id: UUID
    var displayName: String
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String
}

enum WeatherPlaceSelection: Codable, Equatable, Sendable {
    case myLocation
    case saved(UUID)

    private enum CodingKeys: String, CodingKey {
        case kind
        case savedCityId
    }

    private enum Kind: String, Codable {
        case myLocation
        case saved
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .kind)
        switch kind {
        case .myLocation:
            self = .myLocation
        case .saved:
            self = .saved(try c.decode(UUID.self, forKey: .savedCityId))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .myLocation:
            try c.encode(Kind.myLocation, forKey: .kind)
        case .saved(let id):
            try c.encode(Kind.saved, forKey: .kind)
            try c.encode(id, forKey: .savedCityId)
        }
    }
}

extension SavedWeatherPlace {
    init(from place: WeatherPlace) {
        self.init(
            id: UUID(),
            displayName: place.displayLine,
            latitude: place.latitude,
            longitude: place.longitude,
            timeZoneIdentifier: place.timezone
        )
    }
}
