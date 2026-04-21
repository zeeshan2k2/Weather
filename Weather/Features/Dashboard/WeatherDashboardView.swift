import CoreLocation
import SwiftUI
import UIKit
import WidgetKit

struct WeatherDashboardView: View {

    private let forecastRepository: any ForecastRepository

    @Environment(\.scenePhase) private var scenePhase
    @State private var lastEnteredBackgroundAt: Date?

    @StateObject private var locationProvider = WeatherLocationProvider()

    @AppStorage("weatherCityName", store: AppGroupWeatherDefaults.shared) private var storedCityName = ""
    @AppStorage("weatherLatitude", store: AppGroupWeatherDefaults.shared) private var storedLatitudeString = ""
    @AppStorage("weatherLongitude", store: AppGroupWeatherDefaults.shared) private var storedLongitudeString = ""
    @AppStorage("weatherTimezone", store: AppGroupWeatherDefaults.shared) private var storedTimezone = ""
    @AppStorage(AppGroupWeatherDefaults.Key.useCelsius, store: AppGroupWeatherDefaults.shared) private var useCelsius = false

    @StateObject private var model: WeatherDashboardModel

    init(forecastRepository: any ForecastRepository = RemoteForecastRepository()) {
        self.forecastRepository = forecastRepository
        _model = StateObject(wrappedValue: WeatherDashboardModel(forecastRepository: forecastRepository))
    }
    @State private var dayDetailSelection: WeatherDay?
    @State private var isFetchingLocation = false
    @State private var locationErrorMessage: String?
    @State private var showForecastInsight = false
    @State private var navigationPath: [WeatherNavigationRoute] = []

    @State private var showLocationAccessRequiredUI = false

    private var hasValidStoredCoordinates: Bool {
        let city = storedCityName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else { return false }
        guard let lat = Double(storedLatitudeString),
              let lon = Double(storedLongitudeString),
              lat.isFinite, lon.isFinite,
              abs(lat) <= 90, abs(lon) <= 180
        else { return false }
        let tz = storedTimezone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tz.isEmpty, TimeZone(identifier: tz) != nil else { return false }
        return true
    }

    private var selectedLatitude: Double {
        Double(storedLatitudeString) ?? 0
    }

    private var selectedLongitude: Double {
        Double(storedLongitudeString) ?? 0
    }

    private var unitSuffix: String {
        useCelsius ? "C" : "F"
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            dashboardRoot
        }
        .overlay(alignment: .top) {

            if navigationPath.isEmpty {
                DashboardTopRetryControl(
                    errorMessage: model.errorMessage,
                    isLoading: model.isLoading,
                    pendingManualRetryProgress: $model.pendingManualRetryProgress,
                    onRetry: {
                        guard hasValidStoredCoordinates else { return }
                        await model.loadForecast(
                            isManualRetry: true,
                            latitude: selectedLatitude,
                            longitude: selectedLongitude,
                            timeZoneIdentifier: storedTimezone
                        )
                    }
                )
                .padding(.top, 0)
            }
        }
        .alert("Location", isPresented: Binding(
            get: { locationErrorMessage != nil },
            set: { if !$0 { locationErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { locationErrorMessage = nil }
        } message: {
            Text(locationErrorMessage ?? "")
        }
        .onChange(of: "\(storedLatitudeString)|\(storedLongitudeString)|\(storedTimezone)|\(storedCityName)") { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: hasValidStoredCoordinates) { valid in
            guard !valid else { return }
            model.resetDisplayState()
            Task { await refreshDashboardWeatherIfPossible() }
        }
        .onChange(of: useCelsius) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                lastEnteredBackgroundAt = Date()
            case .active:
                Task { await refreshDashboardWeatherIfPossible() }
                guard let backgroundAt = lastEnteredBackgroundAt else { return }
                lastEnteredBackgroundAt = nil
                let away = Date().timeIntervalSince(backgroundAt)
                guard away >= 5 * 60 else { return }
                let dataIsStale: Bool
                if let last = model.lastUpdatedAt {
                    dataIsStale = Date().timeIntervalSince(last) > 15 * 60
                } else {
                    dataIsStale = true
                }
                guard dataIsStale else { return }
                Task {
                    guard hasValidStoredCoordinates else { return }
                    await model.loadForecast(
                        isManualRetry: false,
                        latitude: selectedLatitude,
                        longitude: selectedLongitude,
                        timeZoneIdentifier: storedTimezone
                    )
                }
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var dashboardRoot: some View {
        dashboardMainZStack
            .overlay(alignment: .bottomTrailing) { dashboardBottomTrailingOverlay }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navigationPath.append(.places)
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.title3.weight(.semibold))
                            .dashboardToolbarGlyphChrome()
                    }
                    .accessibilityLabel("Places")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await resolveCurrentLocationForDashboard(fromUserTap: true) }
                    } label: {
                        Group {
                            if isFetchingLocation {
                                ProgressView()
                                    .scaleEffect(0.85)
                                    .tint(.white.opacity(0.95))
                            } else {
                                Image(systemName: "location.circle.fill")
                                    .font(.title3.weight(.semibold))
                                    .dashboardToolbarGlyphChrome()
                            }
                        }
                        .frame(minWidth: 28, minHeight: 28)
                    }
                    .disabled(isFetchingLocation)
                    .accessibilityLabel("Current location")
                }
            }
            .sheet(isPresented: $showForecastInsight) { forecastInsightSheet }
            .sheet(item: $dayDetailSelection) { selected in
                dayDetailSheetContent(selected)
            }
            .task(id: "\(storedLatitudeString)|\(storedLongitudeString)|\(storedTimezone)|\(storedCityName)") {
                await refreshDashboardWeatherIfPossible()
            }
            .navigationDestination(for: WeatherNavigationRoute.self) { route in
                navigationDestinationView(for: route)
            }
    }

    private var dashboardMainZStack: some View {
        ZStack {
            BackgroundView(
                weatherCode: model.currentWeatherCode,
                isDay: model.currentIsDay,
                temperatureF: model.currentTemp
            )
            .animation(.easeInOut(duration: 0.85), value: model.currentWeatherCode)
            .animation(.easeInOut(duration: 0.85), value: model.currentIsDay)
            .animation(.easeInOut(duration: 0.85), value: model.currentTemp)
            .edgesIgnoringSafeArea(.all)

            if model.showLoadFailurePlaceholder {
                DashboardLoadFailureView(
                    loadFailedOffline: model.loadFailedOffline,
                    errorMessage: model.errorMessage
                )
            } else {
                dashboardScrollContent
            }
        }
    }

    private var dashboardScrollContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !storedCityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    CityTextView(cityName: storedCityName)
                }
                dashboardMiddleSection
                if let label = model.lastUpdatedLabel {
                    dashboardUpdatedLabel(label)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 112)
        }
        .refreshable {
            guard hasValidStoredCoordinates else { return }
            await model.loadForecast(
                isManualRetry: false,
                latitude: selectedLatitude,
                longitude: selectedLongitude,
                timeZoneIdentifier: storedTimezone
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var dashboardMiddleSection: some View {
        if showLocationAccessRequiredUI && model.weatherData.isEmpty && !model.isLoading {
            DashboardLocationAccessView(
                onOpenSettings: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                onSearchPlaces: {
                    navigationPath.append(.places)
                }
            )
            .frame(minHeight: 220)
            .frame(maxWidth: .infinity)
        } else if model.weatherData.isEmpty && model.isLoading && model.errorMessage == nil {
            VStack(spacing: 18) {
                ProgressView()
                    .tint(.white)
                Text("Updating weather…")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .frame(minHeight: 220)
            .frame(maxWidth: .infinity)
        } else if !model.weatherData.isEmpty {
            MainWeatherView(
                imageName: model.mainHeroSymbol,
                temperature: DashboardTemperature.display(fahrenheit: model.currentTemp, useCelsius: useCelsius),
                unit: unitSuffix,
                conditionText: WeatherPresentation.conditionDescription(
                    for: model.currentWeatherCode,
                    isDay: model.currentIsDay
                )
            )
            DashboardForecastStripsSection(
                hourlySlice: model.hourlyForecastSliceFromNow(timeZoneIdentifier: storedTimezone),
                weatherDays: model.weatherData,
                timeZoneIdentifier: storedTimezone,
                currentIsDay: model.currentIsDay,
                useCelsius: useCelsius,
                onSelectDay: { dayDetailSelection = $0 }
            )
            DashboardWeatherStatsGrid(
                apparentTempF: model.apparentTempF,
                currentTemp: model.currentTemp,
                humidityPercent: model.humidityPercent,
                windSpeedMph: model.windSpeedMph,
                precipitationMm: model.precipitationMm,
                todayPrecipitationChance: model.weatherData.first?.precipitationProbabilityMax,
                useCelsius: useCelsius
            )
        }
    }

    private func dashboardUpdatedLabel(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.72))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
    }

    @ViewBuilder
    private var dashboardBottomTrailingOverlay: some View {
        if !model.showLoadFailurePlaceholder {
            VStack(alignment: .trailing, spacing: 10) {
                DashboardUnitToggleButton(useCelsius: $useCelsius)
                DashboardAIInsightButton {
                    showForecastInsight = true
                }
            }
            .padding(.trailing, 14)
            .padding(.bottom, 10)
        }
    }

    private var forecastInsightSheet: some View {
        ForecastInsightSheet(
            payload: ForecastInsightCopyBuilder.build(
                model: model,
                cityName: storedCityName,
                useCelsius: useCelsius,
                unitSuffix: unitSuffix,
                timeZoneIdentifier: storedTimezone
            )
        )
    }

    private func dayDetailSheetContent(_ selected: WeatherDay) -> some View {
        DayDetailView(
            summary: selected,
            hourly: model.hourlyItems(forDayId: selected.id, timeZoneIdentifier: storedTimezone),
            timeZoneIdentifier: storedTimezone,
            useCelsius: useCelsius,
            cityName: storedCityName,
            humidityPercent: model.humidityPercent,
            windSpeedMph: model.windSpeedMph,
            longDateString: WeatherDateFormatting.longDateLabel(dayId: selected.id, timeZoneIdentifier: storedTimezone)
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func navigationDestinationView(for route: WeatherNavigationRoute) -> some View {
        switch route {
        case .places:
            PlacesListView(
                forecastRepository: forecastRepository,
                onDone: {
                    if !navigationPath.isEmpty {
                        navigationPath.removeLast()
                    }
                },
                onSearchPicked: { place in

                    navigationPath.append(.preview(place))
                },
                onRequestMyLocationWithGPS: {
                    await resolveCurrentLocationForDashboard(fromUserTap: true)
                }
            )
        case .preview(let place):
            SearchPreviewDashboardView(
                place: place,
                forecastRepository: forecastRepository,
                onDismiss: {

                    if !navigationPath.isEmpty {
                        navigationPath.removeLast()
                    }
                },
                onAdd: {
                    let saved = WeatherPlaceStore.addOrSelectSavedCity(from: place)
                    WeatherPlaceStore.saveSelection(.saved(saved.id))
                    WeatherPlaceStore.mirrorActiveForecastToLegacyKeys(savedPlace: saved)
                    navigationPath.removeAll()
                    WidgetCenter.shared.reloadAllTimelines()
                }
            )
        }
    }

    @discardableResult
    private func resolveCurrentLocationForDashboard(fromUserTap: Bool = false) async -> Bool {
        guard !isFetchingLocation else { return false }
        isFetchingLocation = true
        defer { isFetchingLocation = false }
        do {
            let place = try await locationProvider.resolveCurrentPlace()
            storedLatitudeString = String(place.latitude)
            storedLongitudeString = String(place.longitude)
            storedTimezone = place.timeZoneIdentifier
            storedCityName = place.cityLine
            WeatherPlaceStore.saveSelection(.myLocation)
            WeatherPlaceStore.mirrorActiveForecastToLegacyKeys(
                displayName: place.cityLine,
                latitude: place.latitude,
                longitude: place.longitude,
                timeZoneIdentifier: place.timeZoneIdentifier
            )
            WeatherPlaceStore.saveMyLocationSnapshot(
                displayName: place.cityLine,
                latitude: place.latitude,
                longitude: place.longitude,
                timeZoneIdentifier: place.timeZoneIdentifier
            )
            showLocationAccessRequiredUI = false
            return true
        } catch let error as WeatherLocationError {
            if case .accessDenied = error {
                if fromUserTap || hasValidStoredCoordinates {
                    locationErrorMessage = error.localizedDescription
                } else if !hasValidStoredCoordinates {
                    showLocationAccessRequiredUI = true
                }
            } else {
                locationErrorMessage = error.localizedDescription
            }
            return false
        } catch {
            locationErrorMessage = error.localizedDescription
            return false
        }
    }

    private func refreshDashboardWeatherIfPossible() async {
        let selection = WeatherPlaceStore.loadSelection()
        switch selection {
        case .saved:
            showLocationAccessRequiredUI = false
            WeatherPlaceStore.syncLegacyKeysWithSavedSelectionIfNeeded()
            guard hasValidStoredCoordinates else { return }
            await model.loadForecast(
                isManualRetry: false,
                latitude: selectedLatitude,
                longitude: selectedLongitude,
                timeZoneIdentifier: storedTimezone
            )
        case .myLocation:
            await refreshForecastForMyLocationSelection()
        }
    }

    private func refreshForecastForMyLocationSelection() async {
        let status = locationProvider.authorizationStatus
        switch status {
        case .denied, .restricted:
            if hasValidStoredCoordinates {
                showLocationAccessRequiredUI = false
                await model.loadForecast(
                    isManualRetry: false,
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                    timeZoneIdentifier: storedTimezone
                )
            } else {
                showLocationAccessRequiredUI = true
            }
        case .notDetermined, .authorizedWhenInUse, .authorizedAlways:
            if hasValidStoredCoordinates {
                showLocationAccessRequiredUI = false
                await model.loadForecast(
                    isManualRetry: false,
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                    timeZoneIdentifier: storedTimezone
                )
                return
            }
            showLocationAccessRequiredUI = false
            let ok = await resolveCurrentLocationForDashboard()
            if ok, hasValidStoredCoordinates {
                await model.loadForecast(
                    isManualRetry: false,
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                    timeZoneIdentifier: storedTimezone
                )
            } else if !hasValidStoredCoordinates {
                let s = locationProvider.authorizationStatus
                if s == .denied || s == .restricted {
                    showLocationAccessRequiredUI = true
                }
            }
        @unknown default:
            if hasValidStoredCoordinates {
                showLocationAccessRequiredUI = false
                await model.loadForecast(
                    isManualRetry: false,
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                    timeZoneIdentifier: storedTimezone
                )
            } else {
                showLocationAccessRequiredUI = true
            }
        }
    }
}

#Preview {
    WeatherDashboardView()
}
