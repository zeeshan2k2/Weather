import Foundation

/// Shared storage for the main app and widget extension (`App Group`).
enum AppGroupWeatherDefaults {
    static let suiteName = "group.com.zeeshan.Weather"

    /// Prefer app group; fall back to standard defaults only if the suite is unavailable (unexpected).
    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    enum Key {
        static let cityName = "weatherCityName"
        static let latitude = "weatherLatitude"
        static let longitude = "weatherLongitude"
        static let timezone = "weatherTimezone"
        static let useCelsius = "weatherUseCelsius"
    }

    /// One-time copy from `UserDefaults.standard` so existing installs keep their city after enabling the App Group.
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
