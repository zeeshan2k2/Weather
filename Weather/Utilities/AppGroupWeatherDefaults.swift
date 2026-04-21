import Foundation

enum AppGroupWeatherDefaults {
    static let suiteName = "group.com.zeeshan.Weather"

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    enum Key {
        static let cityName = "weatherCityName"
        static let latitude = "weatherLatitude"
        static let longitude = "weatherLongitude"
        static let timezone = "weatherTimezone"
        static let useCelsius = "weatherUseCelsius"

        static let savedPlacesV1 = "weatherSavedPlacesV1"

        static let placeSelectionV1 = "weatherPlaceSelectionV1"

        static let myLocationSnapshotCityName = "weatherMyLocationSnapshotCityName"
        static let myLocationSnapshotLatitude = "weatherMyLocationSnapshotLatitude"
        static let myLocationSnapshotLongitude = "weatherMyLocationSnapshotLongitude"
        static let myLocationSnapshotTimezone = "weatherMyLocationSnapshotTimezone"
    }

    static let fallbackCityDisplayName = "Cupertino, CA"
    static let fallbackTimeZoneIdentifier = "America/Los_Angeles"

    static func clearForecastCoordinateKeys() {
        let g = shared
        g.removeObject(forKey: Key.cityName)
        g.removeObject(forKey: Key.latitude)
        g.removeObject(forKey: Key.longitude)
        g.removeObject(forKey: Key.timezone)
    }

    static func clearMyLocationSnapshotKeys() {
        let g = shared
        g.removeObject(forKey: Key.myLocationSnapshotCityName)
        g.removeObject(forKey: Key.myLocationSnapshotLatitude)
        g.removeObject(forKey: Key.myLocationSnapshotLongitude)
        g.removeObject(forKey: Key.myLocationSnapshotTimezone)
    }

    static func migrateFromStandardUserDefaultsIfNeeded() {
        guard let group = UserDefaults(suiteName: suiteName) else { return }
        if group.object(forKey: Key.latitude) != nil { return }

        let standard = UserDefaults.standard
        guard standard.object(forKey: Key.latitude) != nil else { return }

        for key in [Key.cityName, Key.latitude, Key.longitude, Key.timezone] {
            if let value = standard.object(forKey: key) {
                group.set(value, forKey: key)
            }
        }
    }
}
