
import SwiftUI

@main
struct WeatherApp: App {
    init() {
        AppGroupWeatherDefaults.migrateFromStandardUserDefaultsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            WeatherDashboardView()
        }
    }
}
