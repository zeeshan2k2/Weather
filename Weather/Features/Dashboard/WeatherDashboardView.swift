
import SwiftUI
import WidgetKit

struct WeatherDashboardView: View {

    private let forecastRepository: any ForecastRepository

    @StateObject private var locationProvider = WeatherLocationProvider()

    @AppStorage("weatherCityName", store: AppGroupWeatherDefaults.shared) private var storedCityName = "Cupertino, CA"
    @AppStorage("weatherLatitude", store: AppGroupWeatherDefaults.shared) private var storedLatitudeString = "37.3230"
    @AppStorage("weatherLongitude", store: AppGroupWeatherDefaults.shared) private var storedLongitudeString = "-122.0322"
    @AppStorage("weatherTimezone", store: AppGroupWeatherDefaults.shared) private var storedTimezone = "America/Los_Angeles"
    @AppStorage(AppGroupWeatherDefaults.Key.useCelsius, store: AppGroupWeatherDefaults.shared) private var useCelsius = false

    @StateObject private var model: WeatherDashboardModel

    init(forecastRepository: any ForecastRepository = RemoteForecastRepository()) {
        self.forecastRepository = forecastRepository
        _model = StateObject(wrappedValue: WeatherDashboardModel(forecastRepository: forecastRepository))
    }
    @State private var showCitySearch = false
    @State private var dayDetailSelection: WeatherDay?
    @State private var isFetchingLocation = false
    @State private var locationErrorMessage: String?
    @State private var showForecastInsight = false

    private var selectedLatitude: Double {
        Double(storedLatitudeString) ?? 37.3230
    }

    private var selectedLongitude: Double {
        Double(storedLongitudeString) ?? -122.0322
    }

    private var unitSuffix: String {
        useCelsius ? "C" : "F"
    }

    var body: some View {
        NavigationStack {
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
                    ScrollView {
                        VStack(spacing: 16) {
                            CityTextView(cityName: storedCityName)

                            Group {
                                if model.weatherData.isEmpty && model.isLoading && model.errorMessage == nil {
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

                            if let label = model.lastUpdatedLabel {
                                Text(label)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.72))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 4)
                                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 112)
                    }
                    .refreshable {
                        await model.loadForecast(
                            isManualRetry: false,
                            latitude: selectedLatitude,
                            longitude: selectedLongitude,
                            timeZoneIdentifier: storedTimezone
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .overlay(alignment: .bottomTrailing) {
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
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            Task { await useCurrentLocationTapped() }
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

                        Button {
                            showCitySearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title3.weight(.semibold))
                                .dashboardToolbarGlyphChrome()
                        }
                        .accessibilityLabel("Search city")
                    }
                }
            }
            .sheet(isPresented: $showForecastInsight) {
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
            .sheet(isPresented: $showCitySearch) {
                CitySearchView(forecastRepository: forecastRepository) { place in
                    storedCityName = "\(place.name), \(place.country)"
                    storedLatitudeString = String(place.latitude)
                    storedLongitudeString = String(place.longitude)
                    storedTimezone = place.timezone
                }
            }
            .sheet(item: $dayDetailSelection) { selected in
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
            .task(id: "\(storedLatitudeString)|\(storedLongitudeString)|\(storedTimezone)") {
                await model.loadForecast(
                    isManualRetry: false,
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                    timeZoneIdentifier: storedTimezone
                )
            }
        }
        .overlay(alignment: .top) {
            DashboardTopRetryControl(
                errorMessage: model.errorMessage,
                isLoading: model.isLoading,
                pendingManualRetryProgress: $model.pendingManualRetryProgress,
                onRetry: {
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
        .onChange(of: useCelsius) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func useCurrentLocationTapped() async {
        guard !isFetchingLocation else { return }
        isFetchingLocation = true
        defer { isFetchingLocation = false }
        do {
            let place = try await locationProvider.resolveCurrentPlace()
            storedLatitudeString = String(place.latitude)
            storedLongitudeString = String(place.longitude)
            storedTimezone = place.timeZoneIdentifier
            storedCityName = place.cityLine
        } catch let error as WeatherLocationError {
            locationErrorMessage = error.localizedDescription
        } catch {
            locationErrorMessage = error.localizedDescription
        }
    }
}


#Preview {
    WeatherDashboardView()
}
