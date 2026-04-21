import Foundation

enum WeatherPlaceStore {
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private static let decoder = JSONDecoder()

    private static var defaults: UserDefaults { AppGroupWeatherDefaults.shared }

    static func loadSavedPlaces() -> [SavedWeatherPlace] {
        guard let data = defaults.data(forKey: AppGroupWeatherDefaults.Key.savedPlacesV1),
              let places = try? decoder.decode([SavedWeatherPlace].self, from: data)
        else {
            return []
        }
        return places
    }

    static func saveSavedPlaces(_ places: [SavedWeatherPlace]) {
        guard let data = try? encoder.encode(places) else { return }
        defaults.set(data, forKey: AppGroupWeatherDefaults.Key.savedPlacesV1)
    }

    static func loadSelection() -> WeatherPlaceSelection {
        guard let data = defaults.data(forKey: AppGroupWeatherDefaults.Key.placeSelectionV1),
              let selection = try? decoder.decode(WeatherPlaceSelection.self, from: data)
        else {
            return .myLocation
        }
        return selection
    }

    static func saveSelection(_ selection: WeatherPlaceSelection) {
        guard let data = try? encoder.encode(selection) else { return }
        defaults.set(data, forKey: AppGroupWeatherDefaults.Key.placeSelectionV1)
    }

    static func resolvedSavedPlace(selection: WeatherPlaceSelection, savedPlaces: [SavedWeatherPlace]) -> SavedWeatherPlace? {
        guard case .saved(let id) = selection else { return nil }
        return savedPlaces.first { $0.id == id }
    }

    @discardableResult
    static func addOrSelectSavedCity(from place: WeatherPlace) -> SavedWeatherPlace {
        var list = loadSavedPlaces()
        let candidate = SavedWeatherPlace(from: place)
        if let idx = list.firstIndex(where: { coordinatesMatch($0, candidate) }) {
            let id = list[idx].id
            let updated = SavedWeatherPlace(
                id: id,
                displayName: candidate.displayName,
                latitude: candidate.latitude,
                longitude: candidate.longitude,
                timeZoneIdentifier: candidate.timeZoneIdentifier
            )
            list[idx] = updated
            saveSavedPlaces(list)
            return updated
        }
        list.append(candidate)
        saveSavedPlaces(list)
        return candidate
    }

    private static func coordinatesMatch(_ a: SavedWeatherPlace, _ b: SavedWeatherPlace) -> Bool {
        abs(a.latitude - b.latitude) < 0.02 && abs(a.longitude - b.longitude) < 0.02
    }

    static func mirrorActiveForecastToLegacyKeys(displayName: String, latitude: Double, longitude: Double, timeZoneIdentifier: String) {
        defaults.set(displayName, forKey: AppGroupWeatherDefaults.Key.cityName)
        defaults.set(String(latitude), forKey: AppGroupWeatherDefaults.Key.latitude)
        defaults.set(String(longitude), forKey: AppGroupWeatherDefaults.Key.longitude)
        defaults.set(timeZoneIdentifier, forKey: AppGroupWeatherDefaults.Key.timezone)
    }

    static func saveMyLocationSnapshot(displayName: String, latitude: Double, longitude: Double, timeZoneIdentifier: String) {
        defaults.set(displayName, forKey: AppGroupWeatherDefaults.Key.myLocationSnapshotCityName)
        defaults.set(String(latitude), forKey: AppGroupWeatherDefaults.Key.myLocationSnapshotLatitude)
        defaults.set(String(longitude), forKey: AppGroupWeatherDefaults.Key.myLocationSnapshotLongitude)
        defaults.set(timeZoneIdentifier, forKey: AppGroupWeatherDefaults.Key.myLocationSnapshotTimezone)
    }

    static func clearForecastAndLocationSnapshotsForEmptySavedList() {
        AppGroupWeatherDefaults.clearForecastCoordinateKeys()
        AppGroupWeatherDefaults.clearMyLocationSnapshotKeys()
    }

    static func mirrorActiveForecastToLegacyKeys(savedPlace: SavedWeatherPlace) {
        mirrorActiveForecastToLegacyKeys(
            displayName: savedPlace.displayName,
            latitude: savedPlace.latitude,
            longitude: savedPlace.longitude,
            timeZoneIdentifier: savedPlace.timeZoneIdentifier
        )
    }

    static func syncLegacyKeysWithSavedSelectionIfNeeded() {
        let places = loadSavedPlaces()
        let selection = loadSelection()
        guard let place = resolvedSavedPlace(selection: selection, savedPlaces: places) else { return }
        mirrorActiveForecastToLegacyKeys(savedPlace: place)
    }

    static func migrateMultiCityPersistenceIfNeeded() {
        migrateMyLocationSnapshotKeysIfNeeded()

        guard defaults.data(forKey: AppGroupWeatherDefaults.Key.savedPlacesV1) == nil else {
            syncLegacyKeysWithSavedSelectionIfNeeded()
            return
        }

        let latString = defaults.string(forKey: AppGroupWeatherDefaults.Key.latitude)
        let lonString = defaults.string(forKey: AppGroupWeatherDefaults.Key.longitude)

        if let latString,
           let lonString,
           let lat = Double(latString),
           let lon = Double(lonString)
        {
            let name = defaults.string(forKey: AppGroupWeatherDefaults.Key.cityName) ?? AppGroupWeatherDefaults.fallbackCityDisplayName
            let tz = defaults.string(forKey: AppGroupWeatherDefaults.Key.timezone) ?? AppGroupWeatherDefaults.fallbackTimeZoneIdentifier
            let place = SavedWeatherPlace(id: UUID(), displayName: name, latitude: lat, longitude: lon, timeZoneIdentifier: tz)
            saveSavedPlaces([place])
            saveSelection(.saved(place.id))
            mirrorActiveForecastToLegacyKeys(savedPlace: place)
        } else {
            AppGroupWeatherDefaults.clearForecastCoordinateKeys()
            saveSavedPlaces([])
            saveSelection(.myLocation)
        }
    }

    private static func migrateMyLocationSnapshotKeysIfNeeded() {
        guard defaults.string(forKey: AppGroupWeatherDefaults.Key.myLocationSnapshotLatitude) == nil else { return }

        if loadSelection() == .myLocation,
           let name = defaults.string(forKey: AppGroupWeatherDefaults.Key.cityName),
           let lat = defaults.string(forKey: AppGroupWeatherDefaults.Key.latitude),
           let lon = defaults.string(forKey: AppGroupWeatherDefaults.Key.longitude),
           let tz = defaults.string(forKey: AppGroupWeatherDefaults.Key.timezone)
        {
            defaults.set(name, forKey: AppGroupWeatherDefaults.Key.myLocationSnapshotCityName)
            defaults.set(lat, forKey: AppGroupWeatherDefaults.Key.myLocationSnapshotLatitude)
            defaults.set(lon, forKey: AppGroupWeatherDefaults.Key.myLocationSnapshotLongitude)
            defaults.set(tz, forKey: AppGroupWeatherDefaults.Key.myLocationSnapshotTimezone)
        } else {
            AppGroupWeatherDefaults.clearMyLocationSnapshotKeys()
        }
    }
}
