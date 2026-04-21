import Combine
import SwiftUI
import WidgetKit

struct PlacesListView: View {
    let forecastRepository: any ForecastRepository
    var onDone: () -> Void
    var onSearchPicked: (WeatherPlace) -> Void

    var onRequestMyLocationWithGPS: () async -> Bool

    @Environment(\.editMode) private var editMode
    @StateObject private var placesConnectivity = PlacesListConnectivityModel()
    @StateObject private var citySearchModel: CitySearchModel

    init(
        forecastRepository: any ForecastRepository,
        onDone: @escaping () -> Void,
        onSearchPicked: @escaping (WeatherPlace) -> Void,
        onRequestMyLocationWithGPS: @escaping () async -> Bool
    ) {
        self.forecastRepository = forecastRepository
        self.onDone = onDone
        self.onSearchPicked = onSearchPicked
        self.onRequestMyLocationWithGPS = onRequestMyLocationWithGPS
        _citySearchModel = StateObject(wrappedValue: CitySearchModel(forecastRepository: forecastRepository))
    }
    @AppStorage(AppGroupWeatherDefaults.Key.useCelsius, store: AppGroupWeatherDefaults.shared) private var useCelsius = false

    @AppStorage(AppGroupWeatherDefaults.Key.myLocationSnapshotCityName, store: AppGroupWeatherDefaults.shared) private var myLocationCityName = ""
    @AppStorage(AppGroupWeatherDefaults.Key.myLocationSnapshotLatitude, store: AppGroupWeatherDefaults.shared) private var myLocationLatitudeString = ""
    @AppStorage(AppGroupWeatherDefaults.Key.myLocationSnapshotLongitude, store: AppGroupWeatherDefaults.shared) private var myLocationLongitudeString = ""
    @AppStorage(AppGroupWeatherDefaults.Key.myLocationSnapshotTimezone, store: AppGroupWeatherDefaults.shared) private var myLocationTimezone = ""

    @State private var savedPlaces: [SavedWeatherPlace] = []
    @State private var showSearch = false
    @State private var listSelection: WeatherPlaceSelection = .myLocation
    @State private var placesRefreshToken = 0

    private var listRowInsets: EdgeInsets {
        EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18)
    }

    var body: some View {
        ZStack {
            CitySearchScreenGradient()
                .ignoresSafeArea()

            List {
                if placesConnectivity.showOfflineHelp {
                    Section {
                        PlacesOfflineListBanner()
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 4, trailing: 18))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                Section {
                    PlacesMyLocationCardRow(
                        forecastRepository: forecastRepository,
                        cityName: myLocationCityName,
                        latitudeString: myLocationLatitudeString,
                        longitudeString: myLocationLongitudeString,
                        timeZoneIdentifier: myLocationTimezone,
                        useCelsius: useCelsius,
                        isSelected: listSelection == .myLocation,
                        refreshToken: placesRefreshToken,
                        connectivity: placesConnectivity
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let mode = editMode?.wrappedValue ?? .inactive
                        guard mode == .inactive else { return }
                        Task {
                            let ok = await onRequestMyLocationWithGPS()
                            if ok {
                                listSelection = .myLocation
                                onDone()
                            }
                        }
                    }
                    .listRowInsets(listRowInsets)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                if !savedPlaces.isEmpty {
                    Section {
                        ForEach(savedPlaces) { place in
                            PlacesSavedPlaceRow(
                                place: place,
                                forecastRepository: forecastRepository,
                                useCelsius: useCelsius,
                                isSelected: isSavedPlaceSelected(place),
                                refreshToken: placesRefreshToken,
                                connectivity: placesConnectivity
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let mode = editMode?.wrappedValue ?? .inactive
                                guard mode == .inactive else { return }
                                selectSaved(place)
                            }
                            .listRowInsets(listRowInsets)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteSaved)
                        .onMove(perform: moveSaved)
                    } header: {
                        Text("Saved places")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 152)
            .refreshable {
                placesConnectivity.resetForPull()
                await reloadAllPlacesSnapshotsForPull()
                placesRefreshToken &+= 1
            }
        }
        .navigationTitle("Places")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .dashboardToolbarGlyphChrome()
                }
                .accessibilityLabel("Search places")
            }
        }
        .onAppear {
            savedPlaces = WeatherPlaceStore.loadSavedPlaces()
            listSelection = WeatherPlaceStore.loadSelection()
        }
        .sheet(isPresented: $showSearch, onDismiss: {
            citySearchModel.resetForDismiss()
        }, content: {
            CitySearchView(model: citySearchModel) { place in
                showSearch = false
                onSearchPicked(place)
            }
        })
    }

    private func reloadAllPlacesSnapshotsForPull() async {
        if let lat = Double(myLocationLatitudeString), let lon = Double(myLocationLongitudeString) {
            let r = await ForecastPlacesSnapshotCache.shared.load(
                repository: forecastRepository,
                latitude: lat,
                longitude: lon,
                timeZoneIdentifier: myLocationTimezone,
                forceRefresh: true
            )
            placesConnectivity.record(r)
        }
        let places = await MainActor.run { WeatherPlaceStore.loadSavedPlaces() }
        for place in places {
            let r = await ForecastPlacesSnapshotCache.shared.load(
                repository: forecastRepository,
                latitude: place.latitude,
                longitude: place.longitude,
                timeZoneIdentifier: place.timeZoneIdentifier,
                forceRefresh: true
            )
            placesConnectivity.record(r)
        }
    }

    private func isSavedPlaceSelected(_ place: SavedWeatherPlace) -> Bool {
        guard case .saved(let id) = listSelection else { return false }
        return id == place.id
    }

    private func selectSaved(_ place: SavedWeatherPlace) {
        WeatherPlaceStore.saveSelection(.saved(place.id))
        WeatherPlaceStore.mirrorActiveForecastToLegacyKeys(savedPlace: place)
        listSelection = .saved(place.id)
        onDone()
    }

    private func deleteSaved(at offsets: IndexSet) {
        var list = savedPlaces
        let removedIds = offsets.map { list[$0].id }
        list.remove(atOffsets: offsets)
        WeatherPlaceStore.saveSavedPlaces(list)
        savedPlaces = list

        if list.isEmpty {
            WeatherPlaceStore.saveSelection(.myLocation)
            WeatherPlaceStore.clearForecastAndLocationSnapshotsForEmptySavedList()
            WidgetCenter.shared.reloadAllTimelines()
            placesRefreshToken &+= 1
            listSelection = WeatherPlaceStore.loadSelection()
            return
        }

        let selection = WeatherPlaceStore.loadSelection()
        guard case .saved(let selectedId) = selection, removedIds.contains(selectedId) else {
            listSelection = WeatherPlaceStore.loadSelection()
            return
        }
        if let first = list.first {
            WeatherPlaceStore.saveSelection(.saved(first.id))
            WeatherPlaceStore.mirrorActiveForecastToLegacyKeys(savedPlace: first)
        }
        listSelection = WeatherPlaceStore.loadSelection()
    }

    private func moveSaved(from source: IndexSet, to destination: Int) {
        var list = savedPlaces
        list.move(fromOffsets: source, toOffset: destination)
        WeatherPlaceStore.saveSavedPlaces(list)
        savedPlaces = list
    }
}

@MainActor
final class PlacesListConnectivityModel: ObservableObject {
    @Published var showOfflineHelp = false

    func record(_ result: PlacesForecastLoadResult) {
        if result.offlineWithNoData {
            showOfflineHelp = true
        } else if result.snapshot != nil {
            showOfflineHelp = false
        }
    }

    func resetForPull() {
        showOfflineHelp = false
    }
}

private struct PlacesOfflineListBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 4) {
                Text("You're offline")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Forecasts can’t load without a connection. Pull down to retry when you’re back online.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct PlacesMyLocationCardRow: View {
    let forecastRepository: any ForecastRepository
    let cityName: String
    let latitudeString: String
    let longitudeString: String
    let timeZoneIdentifier: String
    let useCelsius: Bool
    let isSelected: Bool
    let refreshToken: Int
    @ObservedObject var connectivity: PlacesListConnectivityModel

    @State private var snapshot: PlacesForecastSnapshot?
    @State private var isLoading = true
    @State private var offlineWithNoData = false
    @State private var usedStaleCache = false

    private var coordinateKey: String {
        "\(latitudeString)|\(longitudeString)|\(timeZoneIdentifier)"
    }

    private var subtitle: String {
        let time = placesShortLocalTime(timeZoneIdentifier: timeZoneIdentifier)
        if time.isEmpty { return "My location" }
        return "My location · \(time)"
    }

    var body: some View {
        PlacesWeatherLocationCard(
            title: cityName,
            subtitle: subtitle,
            snapshot: snapshot,
            isLoading: isLoading,
            useCelsius: useCelsius,
            isSelected: isSelected,
            offlineWithNoData: offlineWithNoData,
            usedStaleCache: usedStaleCache
        )
        .task(id: "\(coordinateKey)-\(refreshToken)") {
            await Task.yield()
            if snapshot == nil {
                isLoading = true
            }
            offlineWithNoData = false
            usedStaleCache = false
            guard
                let lat = Double(latitudeString),
                let lon = Double(longitudeString)
            else {
                isLoading = false
                return
            }
            let result = await ForecastPlacesSnapshotCache.shared.load(
                repository: forecastRepository,
                latitude: lat,
                longitude: lon,
                timeZoneIdentifier: timeZoneIdentifier,
                forceRefresh: false
            )
            connectivity.record(result)
            applyPlacesLoadResult(result, to: $snapshot, offline: $offlineWithNoData, stale: $usedStaleCache, loading: $isLoading)
        }
    }
}

private struct PlacesSavedPlaceRow: View {
    let place: SavedWeatherPlace
    let forecastRepository: any ForecastRepository
    let useCelsius: Bool
    let isSelected: Bool
    let refreshToken: Int
    @ObservedObject var connectivity: PlacesListConnectivityModel

    @State private var snapshot: PlacesForecastSnapshot?
    @State private var isLoading = true
    @State private var offlineWithNoData = false
    @State private var usedStaleCache = false

    var body: some View {
        PlacesWeatherLocationCard(
            title: place.displayName,
            subtitle: placesShortLocalTime(timeZoneIdentifier: place.timeZoneIdentifier),
            snapshot: snapshot,
            isLoading: isLoading,
            useCelsius: useCelsius,
            isSelected: isSelected,
            offlineWithNoData: offlineWithNoData,
            usedStaleCache: usedStaleCache
        )
        .task(id: "\(place.id)-\(refreshToken)") {
            await Task.yield()
            if snapshot == nil {
                isLoading = true
            }
            offlineWithNoData = false
            usedStaleCache = false
            let result = await ForecastPlacesSnapshotCache.shared.load(
                repository: forecastRepository,
                latitude: place.latitude,
                longitude: place.longitude,
                timeZoneIdentifier: place.timeZoneIdentifier,
                forceRefresh: false
            )
            connectivity.record(result)
            applyPlacesLoadResult(result, to: $snapshot, offline: $offlineWithNoData, stale: $usedStaleCache, loading: $isLoading)
        }
    }
}

private func applyPlacesLoadResult(
    _ result: PlacesForecastLoadResult,
    to snapshot: Binding<PlacesForecastSnapshot?>,
    offline: Binding<Bool>,
    stale: Binding<Bool>,
    loading: Binding<Bool>
) {
    let instant = result.fromFreshCache && result.snapshot != nil
    if instant {
        snapshot.wrappedValue = result.snapshot
        offline.wrappedValue = result.offlineWithNoData
        stale.wrappedValue = result.fromStaleCache
        loading.wrappedValue = false
    } else {
        withAnimation(.easeInOut(duration: 0.45)) {
            snapshot.wrappedValue = result.snapshot
            offline.wrappedValue = result.offlineWithNoData
            stale.wrappedValue = result.fromStaleCache
            loading.wrappedValue = false
        }
    }
}

private func placesShortLocalTime(timeZoneIdentifier: String) -> String {
    guard let tz = TimeZone(identifier: timeZoneIdentifier) else { return "" }
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    f.timeZone = tz
    return f.string(from: Date())
}

enum WeatherNavigationRoute: Hashable {
    case places
    case preview(WeatherPlace)
}
