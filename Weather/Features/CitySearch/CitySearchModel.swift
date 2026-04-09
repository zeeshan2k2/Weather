//
//  CitySearchModel.swift
//  Weather
//
//  Debounced place search + result state; `CitySearchView` wires UI.
//

import Combine
import Foundation

final class CitySearchModel: ObservableObject {
    private let forecastRepository: any ForecastRepository

    @Published var searchText = ""
    @Published var results: [WeatherPlace] = []
    @Published var isSearching = false
    /// Last completed search failed due to connectivity (don’t show “No matches”).
    @Published var lastSearchFailedOffline = false

    init(forecastRepository: any ForecastRepository = RemoteForecastRepository()) {
        self.forecastRepository = forecastRepository
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var showHint: Bool {
        trimmedQuery.count < 2 && !isSearching
    }

    var showNoResults: Bool {
        trimmedQuery.count >= 2 && !isSearching && results.isEmpty && !lastSearchFailedOffline
    }

    var showOfflineSearch: Bool {
        trimmedQuery.count >= 2 && !isSearching && lastSearchFailedOffline
    }

    func runDebouncedSearch() async {
        let trimmed = trimmedQuery
        if trimmed.count < 2 {
            results = []
            lastSearchFailedOffline = false
            isSearching = false
            return
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
        let latest = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard latest == trimmed, latest.count >= 2 else { return }

        isSearching = true
        defer { isSearching = false }
        do {
            results = try await forecastRepository.searchPlaces(query: PlaceSearchQuery(rawText: latest))
            lastSearchFailedOffline = false
        } catch {
            if error is CancellationError { return }
            if (error as? URLError)?.code == .cancelled { return }
            results = []
            lastSearchFailedOffline = WeatherPresentation.isLikelyConnectivityFailure(error)
        }
    }
}
