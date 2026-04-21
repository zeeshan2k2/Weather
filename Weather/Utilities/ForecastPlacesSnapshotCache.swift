import Foundation

struct PlacesForecastSnapshot: Sendable {
    var currentTempF: Int
    var highF: Int
    var lowF: Int
    var code: Int
    var isDay: Bool
}

extension PlacesForecastSnapshot: Equatable {
    nonisolated static func == (lhs: PlacesForecastSnapshot, rhs: PlacesForecastSnapshot) -> Bool {
        lhs.currentTempF == rhs.currentTempF
            && lhs.highF == rhs.highF
            && lhs.lowF == rhs.lowF
            && lhs.code == rhs.code
            && lhs.isDay == rhs.isDay
    }
}

struct PlacesForecastLoadResult: Sendable {
    var snapshot: PlacesForecastSnapshot?
    var fromFreshCache: Bool
    var fromStaleCache: Bool
    var offlineWithNoData: Bool
}

extension PlacesForecastLoadResult: Equatable {
    nonisolated static func == (lhs: PlacesForecastLoadResult, rhs: PlacesForecastLoadResult) -> Bool {
        lhs.snapshot == rhs.snapshot
            && lhs.fromFreshCache == rhs.fromFreshCache
            && lhs.fromStaleCache == rhs.fromStaleCache
            && lhs.offlineWithNoData == rhs.offlineWithNoData
    }
}

actor ForecastPlacesSnapshotCache {
    static let shared = ForecastPlacesSnapshotCache()

    private struct Entry: Sendable {
        var snapshot: PlacesForecastSnapshot
        var fetchedAt: Date
    }

    private var storage: [String: Entry] = [:]
    private var inFlight: [String: Task<FetchOutcome, Never>] = [:]

    private let ttl: TimeInterval = 30 * 60

    private enum FetchOutcome: Equatable, Sendable {
        case success(PlacesForecastSnapshot)
        case failure(offline: Bool)
    }

    static func cacheKey(latitude: Double, longitude: Double, timeZoneIdentifier: String) -> String {
        String(format: "%.5f|%.5f|%@", latitude, longitude, timeZoneIdentifier)
    }

    static func makeSnapshot(from forecast: WeatherForecast) -> PlacesForecastSnapshot {
        let today = forecast.daily.first
        return PlacesForecastSnapshot(
            currentTempF: forecast.currentTempF,
            highF: today?.highTempF ?? forecast.currentTempF,
            lowF: today?.lowTempF ?? forecast.currentTempF,
            code: forecast.currentCode,
            isDay: forecast.currentIsDay
        )
    }

    func storeFromForecast(_ forecast: WeatherForecast, latitude: Double, longitude: Double, timeZoneIdentifier: String) {
        let key = Self.cacheKey(latitude: latitude, longitude: longitude, timeZoneIdentifier: timeZoneIdentifier)
        let snap = Self.makeSnapshot(from: forecast)
        storage[key] = Entry(snapshot: snap, fetchedAt: Date())
    }

    func load(
        repository: any ForecastRepository,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        forceRefresh: Bool
    ) async -> PlacesForecastLoadResult {
        let key = Self.cacheKey(latitude: latitude, longitude: longitude, timeZoneIdentifier: timeZoneIdentifier)

        if !forceRefresh, let entry = storage[key], Date().timeIntervalSince(entry.fetchedAt) < ttl {
            return PlacesForecastLoadResult(
                snapshot: entry.snapshot,
                fromFreshCache: true,
                fromStaleCache: false,
                offlineWithNoData: false
            )
        }

        if let existing = inFlight[key] {
            return mapOutcome(await existing.value, staleFallback: storage[key]?.snapshot)
        }

        let staleBeforeFetch = storage[key]?.snapshot

        let task = Task {
            await self.fetchIntoStorage(
                repository: repository,
                latitude: latitude,
                longitude: longitude,
                timeZoneIdentifier: timeZoneIdentifier,
                key: key
            )
        }

        inFlight[key] = task
        let outcome = await task.value
        inFlight[key] = nil

        return mapOutcome(outcome, staleFallback: staleBeforeFetch)
    }

    private func fetchIntoStorage(
        repository: any ForecastRepository,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        key: String
    ) async -> FetchOutcome {
        do {
            let forecast = try await repository.fetchForecast(
                coordinate: MapCoordinate(latitude: latitude, longitude: longitude),
                timeZone: IANATimeZone(identifier: timeZoneIdentifier)
            )
            let snap = Self.makeSnapshot(from: forecast)
            storage[key] = Entry(snapshot: snap, fetchedAt: Date())
            return .success(snap)
        } catch {
            if error is CancellationError { return .failure(offline: false) }
            if (error as? URLError)?.code == .cancelled { return .failure(offline: false) }
            let offline = await WeatherPresentation.isLikelyConnectivityFailure(error)
            return .failure(offline: offline)
        }
    }

    private func mapOutcome(_ outcome: FetchOutcome, staleFallback: PlacesForecastSnapshot?) -> PlacesForecastLoadResult {
        switch outcome {
        case .success(let snap):
            return PlacesForecastLoadResult(
                snapshot: snap,
                fromFreshCache: false,
                fromStaleCache: false,
                offlineWithNoData: false
            )
        case .failure(let offline):
            if let stale = staleFallback {
                return PlacesForecastLoadResult(
                    snapshot: stale,
                    fromFreshCache: false,
                    fromStaleCache: true,
                    offlineWithNoData: false
                )
            }
            return PlacesForecastLoadResult(
                snapshot: nil,
                fromFreshCache: false,
                fromStaleCache: false,
                offlineWithNoData: offline
            )
        }
    }

    static func prefetchSavedPlaces(repository: any ForecastRepository) async {
        let places = await MainActor.run { WeatherPlaceStore.loadSavedPlaces() }
        for place in places {
            if Task.isCancelled { break }
            _ = await ForecastPlacesSnapshotCache.shared.load(
                repository: repository,
                latitude: place.latitude,
                longitude: place.longitude,
                timeZoneIdentifier: place.timeZoneIdentifier,
                forceRefresh: false
            )
        }
    }
}
