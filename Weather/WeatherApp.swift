import SwiftUI

@main
struct WeatherApp: App {
    init() {
        AppGroupWeatherDefaults.migrateFromStandardUserDefaultsIfNeeded()
        WeatherPlaceStore.migrateMultiCityPersistenceIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            WeatherDashboardView()
                .preferredColorScheme(.dark)
        }
    }
}
