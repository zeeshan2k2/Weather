import SwiftUI

struct DashboardLocationAccessView: View {
    var onOpenSettings: () -> Void
    var onSearchPlaces: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .symbolRenderingMode(.hierarchical)

            Text("Location needed")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(
                "Allow location access to see weather where you are, or search for a city in Places."
            )
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.82))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)

            VStack(spacing: 12) {
                Button {
                    onOpenSettings()
                } label: {
                    Text("Open Settings")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.22)))
                }
                .buttonStyle(.plain)

                Button {
                    onSearchPlaces()
                } label: {
                    Text("Search places")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
    }
}

struct DashboardLoadFailureView: View {
    let loadFailedOffline: Bool
    let errorMessage: String?

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    VStack(spacing: 20) {
                        Image(systemName: loadFailedOffline ? "wifi.slash" : "exclamationmark.triangle.fill")
                            .font(.system(size: 72, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                            .symbolRenderingMode(.hierarchical)
                            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)

                        Text(loadFailedOffline ? "No internet connection" : "Couldn’t load weather")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(
                            loadFailedOffline
                                ? "Try connecting to Wi‑Fi or turning on mobile data."
                                : (errorMessage ?? "Check your connection and try again.")
                        )
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 36)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
        }
    }
}

enum DashboardChromeMetrics {
    static let chromeButtonShadow = (color: Color.black.opacity(0.42), radius: CGFloat(5), y: CGFloat(2))

    static let glassSurfaceGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.26),
            Color.white.opacity(0.07),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let glassSurfaceStroke = Color.white.opacity(0.42)

    static let minimalChromeShadow = (color: Color.black.opacity(0.26), radius: CGFloat(2), y: CGFloat(1))

    static let floatingGlassShadow = (color: Color.black.opacity(0.2), radius: CGFloat(4), y: CGFloat(1.5))
    static let chromeFill = Color.white.opacity(0.42)
    static let chromeStroke = Color.white.opacity(0.55)
    static let retrySlotSize: CGFloat = 44
}

struct DashboardTopRetryControl: View {
    let errorMessage: String?
    let isLoading: Bool
    @Binding var pendingManualRetryProgress: Bool
    let onRetry: () async -> Void

    var body: some View {
        Group {
            if errorMessage != nil {
                ZStack(alignment: .center) {
                    if isLoading && pendingManualRetryProgress {
                        retryLoader
                    }
                    if !isLoading {
                        Button {
                            pendingManualRetryProgress = true
                            Task(priority: .userInitiated) {
                                await onRetry()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(DashboardChromeMetrics.chromeFill)
                                    .overlay(Circle().strokeBorder(DashboardChromeMetrics.chromeStroke, lineWidth: 1.25))
                                Image(systemName: "arrow.clockwise")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
                            }
                            .frame(width: DashboardChromeMetrics.retrySlotSize, height: DashboardChromeMetrics.retrySlotSize)
                            .clipShape(Circle())
                            .contentShape(Circle())
                            .shadow(
                                color: DashboardChromeMetrics.chromeButtonShadow.color,
                                radius: DashboardChromeMetrics.chromeButtonShadow.radius,
                                y: DashboardChromeMetrics.chromeButtonShadow.y
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Retry loading weather")
                    }
                }
                .frame(width: DashboardChromeMetrics.retrySlotSize, height: DashboardChromeMetrics.retrySlotSize)
            }
        }
    }

    private var retryLoader: some View {
        ZStack {
            Circle()
                .fill(DashboardChromeMetrics.chromeFill)
                .overlay(Circle().strokeBorder(DashboardChromeMetrics.chromeStroke, lineWidth: 1.25))
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(0.9)
        }
        .frame(width: DashboardChromeMetrics.retrySlotSize, height: DashboardChromeMetrics.retrySlotSize)
        .clipShape(Circle())
        .shadow(
            color: DashboardChromeMetrics.chromeButtonShadow.color,
            radius: DashboardChromeMetrics.chromeButtonShadow.radius,
            y: DashboardChromeMetrics.chromeButtonShadow.y
        )
        .accessibilityLabel("Updating weather")
    }
}

struct DashboardUnitToggleButton: View {
    @Binding var useCelsius: Bool

    private var label: String { useCelsius ? "°C" : "°F" }

    var body: some View {
        Button {
            useCelsius.toggle()
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.82),
                                Color.white.opacity(0.52),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.45), lineWidth: 0.75)
                )
                .mask(alignment: .center) {

                    Rectangle()
                        .overlay(alignment: .center) {
                            Text(label)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .blendMode(.destinationOut)
                        }
                }
                .compositingGroup()
                .shadow(
                    color: DashboardChromeMetrics.floatingGlassShadow.color,
                    radius: DashboardChromeMetrics.floatingGlassShadow.radius,
                    y: DashboardChromeMetrics.floatingGlassShadow.y
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(useCelsius ? "Use Fahrenheit" : "Use Celsius")
    }
}

extension View {

    func dashboardToolbarGlyphChrome() -> some View {
        foregroundStyle(Color.white.opacity(0.95))
            .shadow(
                color: DashboardChromeMetrics.minimalChromeShadow.color,
                radius: DashboardChromeMetrics.minimalChromeShadow.radius,
                y: DashboardChromeMetrics.minimalChromeShadow.y
            )
    }
}

struct DashboardWeatherStatsGrid: View {
    let apparentTempF: Int?
    let currentTemp: Int
    let humidityPercent: Int?
    let windSpeedMph: Double?
    let precipitationMm: Double?
    let todayPrecipitationChance: Int?
    let useCelsius: Bool

    private var unitSuffix: String { useCelsius ? "C" : "F" }

    var body: some View {
        let feelsLikeF = apparentTempF ?? currentTemp
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        let windValue: String = {
            guard let mph = windSpeedMph else { return "—" }
            return String(format: "%.0f mph", mph)
        }()

        LazyVGrid(columns: columns, spacing: 12) {
            WeatherStatTile(
                icon: "thermometer.medium",
                title: "Feels like",
                value: "\(DashboardTemperature.display(fahrenheit: feelsLikeF, useCelsius: useCelsius))°\(unitSuffix)",
                iconStyle: .feelsLike
            )
            WeatherStatTile(
                icon: "humidity.fill",
                title: "Humidity",
                value: humidityPercent.map { "\($0)%" } ?? "—",
                iconStyle: .humidity
            )
            WeatherStatTile(
                icon: "wind",
                title: "Wind",
                value: windValue,
                iconStyle: .wind
            )
            WeatherStatTile(
                icon: "drop.fill",
                title: "Precipitation",
                value: DashboardTemperature.precipitationTileValue(mm: precipitationMm, todayChancePercent: todayPrecipitationChance),
                iconStyle: .precipitation
            )
        }
        .padding(.horizontal, 20)
    }
}

private enum DashboardStripLayout {
    static let hourlyVisibleColumnCount: CGFloat = 5
    static let hourlyColumnSpacing: CGFloat = 12
    static let hourlyStripHorizontalPadding: CGFloat = 6
    static let hourlyStripRowHeight: CGFloat = 96
    static let dailyVisibleColumnCount: CGFloat = 3
    static let dailyColumnSpacing: CGFloat = 10
    static let dailyStripHorizontalPadding: CGFloat = 6
    static let dailyStripRowHeight: CGFloat = 110
    static let forecastStripHStackVerticalPadding: CGFloat = 4

    static func hourlyColumnWidth(containerWidth: CGFloat) -> CGFloat {
        let inner = containerWidth - hourlyStripHorizontalPadding * 2
        let gaps = hourlyColumnSpacing * (hourlyVisibleColumnCount - 1)
        let raw = (inner - gaps) / hourlyVisibleColumnCount
        return max(44, floor(raw))
    }

    static func dailyColumnWidth(containerWidth: CGFloat) -> CGFloat {
        let inner = containerWidth - dailyStripHorizontalPadding * 2
        let gaps = dailyColumnSpacing * (dailyVisibleColumnCount - 1)
        let raw = (inner - gaps) / dailyVisibleColumnCount
        return max(48, floor(raw))
    }
}

struct DashboardForecastStripsSection: View {
    let hourlySlice: [HourlyForecastItem]
    let weatherDays: [WeatherDay]
    let timeZoneIdentifier: String
    let currentIsDay: Bool
    let useCelsius: Bool
    let onSelectDay: (WeatherDay) -> Void

    private var unitSuffix: String { useCelsius ? "C" : "F" }

    private func displayTemp(_ f: Int) -> Int {
        DashboardTemperature.display(fahrenheit: f, useCelsius: useCelsius)
    }

    var body: some View {
        WeatherForecastStripsPanel {
            VStack(alignment: .leading, spacing: 8) {
                if !hourlySlice.isEmpty {
                    ZStack(alignment: .trailing) {
                        GeometryReader { geo in
                            let columnWidth = DashboardStripLayout.hourlyColumnWidth(containerWidth: geo.size.width)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DashboardStripLayout.hourlyColumnSpacing) {
                                    ForEach(hourlySlice) { hour in
                                        hourlyColumn(hour: hour, cellWidth: columnWidth)
                                    }
                                }
                                .padding(.horizontal, DashboardStripLayout.hourlyStripHorizontalPadding)
                                .padding(.vertical, DashboardStripLayout.forecastStripHStackVerticalPadding)
                                .frame(height: geo.size.height, alignment: .top)
                            }
                        }
                        StripScrollHintChevron(
                            isVisible: hourlySlice.count > Int(DashboardStripLayout.hourlyVisibleColumnCount),
                            parentHorizontalContentInset: WeatherForecastStripsPanelLayout.horizontalContentPadding
                        )
                    }
                    .frame(height: DashboardStripLayout.hourlyStripRowHeight)
                }

                ZStack(alignment: .trailing) {
                    GeometryReader { geo in
                        let dayColumnWidth = DashboardStripLayout.dailyColumnWidth(containerWidth: geo.size.width)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DashboardStripLayout.dailyColumnSpacing) {
                                ForEach(weatherDays) { weather in
                                    Button {
                                        withAnimation(.spring(response: 0.48, dampingFraction: 0.86, blendDuration: 0.2)) {
                                            onSelectDay(weather)
                                        }
                                    } label: {
                                        WeatherDayView(
                                            dayOfWeek: weather.dayOfWeek,
                                            imageName: weather.imageName,
                                            highTemperature: displayTemp(weather.temperature),
                                            lowTemperature: weather.lowTempF.map { displayTemp($0) },
                                            unit: unitSuffix,
                                            stripCompact: true
                                        )
                                        .frame(width: dayColumnWidth)
                                    }
                                    .buttonStyle(DayCardPressStyle())
                                }
                            }
                            .padding(.horizontal, DashboardStripLayout.dailyStripHorizontalPadding)
                            .padding(.vertical, DashboardStripLayout.forecastStripHStackVerticalPadding)
                            .frame(height: geo.size.height, alignment: .bottom)
                        }
                    }
                    StripScrollHintChevron(
                        isVisible: weatherDays.count > Int(DashboardStripLayout.dailyVisibleColumnCount),
                        parentHorizontalContentInset: WeatherForecastStripsPanelLayout.horizontalContentPadding
                    )
                }
                .frame(height: DashboardStripLayout.dailyStripRowHeight)
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func hourlyColumn(hour: HourlyForecastItem, cellWidth: CGFloat) -> some View {
        VStack(alignment: .center, spacing: 6) {
            Text(WeatherDateFormatting.formattedHourLabel(timeISO: hour.timeISO, timeZoneIdentifier: timeZoneIdentifier))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
            WeatherSkyConditionSymbol.resizableImage(
                systemName: WeatherPresentation.symbolName(
                    for: hour.weatherCode,
                    isDay: WeatherDateFormatting.hourlyIsDaylight(
                        timeISO: hour.timeISO,
                        timeZoneIdentifier: timeZoneIdentifier,
                        fallbackIsDay: currentIsDay
                    )
                )
            )
            .frame(width: 28, height: 28)
            .frame(maxWidth: .infinity)
            Text("\(displayTemp(hour.tempF))°\(unitSuffix)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
        }
        .frame(width: cellWidth)
    }
}

struct SearchPreviewDashboardView: View {
    let place: WeatherPlace
    private let forecastRepository: any ForecastRepository
    var onDismiss: () -> Void
    var onAdd: () -> Void

    @AppStorage(AppGroupWeatherDefaults.Key.useCelsius, store: AppGroupWeatherDefaults.shared) private var useCelsius = false

    @StateObject private var model: WeatherDashboardModel
    @State private var dayDetailSelection: WeatherDay?
    @State private var showForecastInsight = false

    init(
        place: WeatherPlace,
        forecastRepository: any ForecastRepository,
        onDismiss: @escaping () -> Void,
        onAdd: @escaping () -> Void
    ) {
        self.place = place
        self.forecastRepository = forecastRepository
        self.onDismiss = onDismiss
        self.onAdd = onAdd
        _model = StateObject(wrappedValue: WeatherDashboardModel(forecastRepository: forecastRepository))
    }

    private var unitSuffix: String { useCelsius ? "C" : "F" }

    var body: some View {
        previewLayers
            .overlay(alignment: .bottomTrailing) { previewBottomTrailing }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .dashboardToolbarGlyphChrome()
                    }
                    .accessibilityLabel("Dismiss")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onAdd()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .dashboardToolbarGlyphChrome()
                    }
                    .accessibilityLabel("Add to Places")
                }
            }
            .sheet(isPresented: $showForecastInsight) { insightSheet }
            .sheet(item: $dayDetailSelection) { selected in
                dayDetailSheet(selected)
            }
            .task(id: "\(place.latitude)|\(place.longitude)|\(place.timezone)") {
                await model.loadForecast(
                    isManualRetry: false,
                    latitude: place.latitude,
                    longitude: place.longitude,
                    timeZoneIdentifier: place.timezone
                )
            }
            .overlay(alignment: .top) { previewRetryOverlay }
    }

    private var previewLayers: some View {
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
                previewScrollContent
            }
        }
    }

    private var previewScrollContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                CityTextView(cityName: place.displayLine)
                previewMiddleGroup
                if let label = model.lastUpdatedLabel {
                    previewUpdatedLabel(label)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 112)
        }
        .refreshable {
            await model.loadForecast(
                isManualRetry: false,
                latitude: place.latitude,
                longitude: place.longitude,
                timeZoneIdentifier: place.timezone
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var previewMiddleGroup: some View {
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
                hourlySlice: model.hourlyForecastSliceFromNow(timeZoneIdentifier: place.timezone),
                weatherDays: model.weatherData,
                timeZoneIdentifier: place.timezone,
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

    private func previewUpdatedLabel(_ label: String) -> some View {
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
    private var previewBottomTrailing: some View {
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

    private var insightSheet: some View {
        ForecastInsightSheet(
            payload: ForecastInsightCopyBuilder.build(
                model: model,
                cityName: place.displayLine,
                useCelsius: useCelsius,
                unitSuffix: unitSuffix,
                timeZoneIdentifier: place.timezone
            )
        )
    }

    private func dayDetailSheet(_ selected: WeatherDay) -> some View {
        DayDetailView(
            summary: selected,
            hourly: model.hourlyItems(forDayId: selected.id, timeZoneIdentifier: place.timezone),
            timeZoneIdentifier: place.timezone,
            useCelsius: useCelsius,
            cityName: place.displayLine,
            humidityPercent: model.humidityPercent,
            windSpeedMph: model.windSpeedMph,
            longDateString: WeatherDateFormatting.longDateLabel(dayId: selected.id, timeZoneIdentifier: place.timezone)
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var previewRetryOverlay: some View {
        DashboardTopRetryControl(
            errorMessage: model.errorMessage,
            isLoading: model.isLoading,
            pendingManualRetryProgress: $model.pendingManualRetryProgress,
            onRetry: {
                await model.loadForecast(
                    isManualRetry: true,
                    latitude: place.latitude,
                    longitude: place.longitude,
                    timeZoneIdentifier: place.timezone
                )
            }
        )
    }
}
