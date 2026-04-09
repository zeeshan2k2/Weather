
import SwiftUI

struct WeatherDashboardView: View {
    
    // Views are recreated on state changes, so local variables don’t persist.
    // @State stores the value outside the view and keeps it alive across re-renders.
    @AppStorage("weatherCityName") private var storedCityName = "Cupertino, CA"
    @AppStorage("weatherLatitude") private var storedLatitudeString = "37.3230"
    @AppStorage("weatherLongitude") private var storedLongitudeString = "-122.0322"
    @AppStorage("weatherTimezone") private var storedTimezone = "America/Los_Angeles"
    
    @State private var showCitySearch = false
    @State private var weatherData: [WeatherDay] = []
    @State private var currentTemp = 72
    @State private var currentWeatherCode = 0
    @State private var currentIsDay = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var useCelsius = false
    @State private var hourlyForecast: [HourlyForecastItem] = []
    @State private var apparentTempF: Int?
    @State private var humidityPercent: Int?
    @State private var precipitationMm: Double?
    @State private var windSpeedMph: Double?
    @State private var windDirectionDegrees: Int?
    @State private var lastUpdatedAt: Date?
    @State private var dayDetailSelection: WeatherDay?
    /// Set when the last failed load was likely due to no connectivity (empty `weatherData` shows centred placeholder).
    @State private var loadFailedOffline = false
    /// Top `ProgressView` only after the user taps retry — never for `.task` / pull-to-refresh (avoids a second spinner under the button).
    @State private var pendingManualRetryProgress = false
    
    /// Hero icon follows the API (conditions + is_day). Background uses the same signals + temperature.
    private var mainHeroSymbol: String {
        WeatherService.symbolName(for: currentWeatherCode, isDay: currentIsDay)
    }
    
    /// All air temperatures from the API (stored in °F) should go through this when shown in the UI.
    private func displayTemperature(fahrenheit: Int) -> Int {
        useCelsius ? Int((Double(fahrenheit) - 32) * 5 / 9) : fahrenheit
    }
    
    private var unitSuffix: String {
        useCelsius ? "C" : "F"
    }
    
    private var hourlySlice24: [HourlyForecastItem] {
        Array(hourlyForecast.prefix(24))
    }

    private func hourlyItems(forDayId dayId: String) -> [HourlyForecastItem] {
        hourlyForecast.filter { $0.timeISO.hasPrefix(dayId) }
    }

    @ViewBuilder
    private func hourlyForecastColumn(hour: HourlyForecastItem, cellWidth: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(WeatherDateFormatting.formattedHourLabel(timeISO: hour.timeISO, timeZoneIdentifier: storedTimezone))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
            Image(systemName: WeatherService.symbolName(
                for: hour.weatherCode,
                isDay: WeatherDateFormatting.hourlyIsDaylight(timeISO: hour.timeISO, timeZoneIdentifier: storedTimezone, fallbackIsDay: currentIsDay)
            ))
            .symbolRenderingMode(.multicolor)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .foregroundStyle(.white)
            Text("\(displayTemperature(fahrenheit: hour.tempF))°\(unitSuffix)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(width: cellWidth)
    }

    private var lastUpdatedLabel: String? {
        guard let lastUpdatedAt else { return nil }
        return "Last updated \(lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private var selectedLatitude: Double {
        Double(storedLatitudeString) ?? 37.3230
    }
    
    private var selectedLongitude: Double {
        Double(storedLongitudeString) ?? -122.0322
    }

    /// Current `precipitation` from Open‑Meteo is rain/snow in the **last hour** (often 0 when dry). When that’s negligible, show today’s **max chance** from the daily forecast instead.
    private func precipitationTileValue(mm: Double?, todayChancePercent: Int?) -> String {
        if let mm, mm >= 0.02 {
            if mm < 1 { return String(format: "%.1f mm", mm) }
            return String(format: "%.0f mm", mm)
        }
        if let chance = todayChancePercent {
            return "\(chance)%"
        }
        if let mm, mm >= 0, mm < 0.02 {
            return "None"
        }
        return "—"
    }
    
    private var weatherStatGrid: some View {
        let feelsLikeF = apparentTempF ?? currentTemp
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        let windValue: String = {
            guard let mph = windSpeedMph else { return "—" }
            let speed = String(format: "%.0f mph", mph)
            if let dir = WeatherService.windDirectionAbbreviation(degrees: windDirectionDegrees) {
                return "\(speed) \(dir)"
            }
            return speed
        }()

        return LazyVGrid(columns: columns, spacing: 12) {
            WeatherStatTile(
                icon: "thermometer.medium",
                title: "Feels like",
                value: "\(displayTemperature(fahrenheit: feelsLikeF))°\(unitSuffix)"
            )
            WeatherStatTile(
                icon: "humidity.fill",
                title: "Humidity",
                value: humidityPercent.map { "\($0)%" } ?? "—"
            )
            WeatherStatTile(
                icon: "wind",
                title: "Wind",
                value: windValue
            )
            WeatherStatTile(
                icon: "drop.fill",
                title: "Precipitation",
                value: precipitationTileValue(mm: precipitationMm, todayChancePercent: weatherData.first?.precipitationProbabilityMax)
            )
        }
        .padding(.horizontal, 20)
    }

    private static let chromeButtonShadow = (color: Color.black.opacity(0.42), radius: CGFloat(5), y: CGFloat(2))
    /// Frosted bubble — opaque enough to read on bright sky gradients.
    private static let chromeFill = Color.white.opacity(0.42)
    private static let chromeStroke = Color.white.opacity(0.55)

    private static let retrySlotSize: CGFloat = 44

    /// Hourly row: exactly this many columns fit in the visible strip without clipping; more hours scroll horizontally.
    private static let hourlyVisibleColumnCount: CGFloat = 5
    private static let hourlyColumnSpacing: CGFloat = 12
    private static let hourlyStripHorizontalPadding: CGFloat = 6
    private static let hourlyStripRowHeight: CGFloat = 96

    /// Multi-day row: three full cards in the visible strip; additional days scroll.
    private static let dailyVisibleColumnCount: CGFloat = 3
    private static let dailyColumnSpacing: CGFloat = 10
    private static let dailyStripHorizontalPadding: CGFloat = 6
    private static let dailyStripRowHeight: CGFloat = 110
    /// Same vertical inset on both strips so space above hours matches space below days inside the panel.
    private static let forecastStripHStackVerticalPadding: CGFloat = 4

    private static func hourlyColumnWidth(containerWidth: CGFloat) -> CGFloat {
        let inner = containerWidth - hourlyStripHorizontalPadding * 2
        let gaps = hourlyColumnSpacing * (hourlyVisibleColumnCount - 1)
        let raw = (inner - gaps) / hourlyVisibleColumnCount
        return max(44, floor(raw))
    }

    private static func dailyColumnWidth(containerWidth: CGFloat) -> CGFloat {
        let inner = containerWidth - dailyStripHorizontalPadding * 2
        let gaps = dailyColumnSpacing * (dailyVisibleColumnCount - 1)
        let raw = (inner - gaps) / dailyVisibleColumnCount
        // Keep exactly three columns across the visible width; don’t force a min width that breaks narrow devices.
        return max(48, floor(raw))
    }

    /// Same chrome as the retry button; `ProgressView` sits on the circle — not inside a `Button`.
    private var weatherRetrySlotLoader: some View {
        ZStack {
            Circle()
                .fill(Self.chromeFill)
                .overlay(Circle().strokeBorder(Self.chromeStroke, lineWidth: 1.25))
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(0.9)
        }
        .frame(width: Self.retrySlotSize, height: Self.retrySlotSize)
        .clipShape(Circle())
        .shadow(
            color: Self.chromeButtonShadow.color,
            radius: Self.chromeButtonShadow.radius,
            y: Self.chromeButtonShadow.y
        )
        .accessibilityLabel("Updating weather")
    }

    /// Fixed 44×44 slot: loader and retry never share the stack — same screen position. No `ProgressView` in the button label.
    @ViewBuilder
    private var weatherTopFetchControl: some View {
        if errorMessage != nil {
            ZStack(alignment: .center) {
                if isLoading && pendingManualRetryProgress {
                    weatherRetrySlotLoader
                }
                if !isLoading {
                    Button {
                        pendingManualRetryProgress = true
                        Task(priority: .userInitiated) {
                            await loadWeather(isManualRetry: true)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Self.chromeFill)
                                .overlay(Circle().strokeBorder(Self.chromeStroke, lineWidth: 1.25))
                            Image(systemName: "arrow.clockwise")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
                        }
                        .frame(width: Self.retrySlotSize, height: Self.retrySlotSize)
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .shadow(
                            color: Self.chromeButtonShadow.color,
                            radius: Self.chromeButtonShadow.radius,
                            y: Self.chromeButtonShadow.y
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Retry loading weather")
                }
            }
            .frame(width: Self.retrySlotSize, height: Self.retrySlotSize)
        }
    }

    /// °C / °F — same bubble fill/stroke as reload (toolbar search uses its own system bubble).
    private var unitToggleFloating: some View {
        Button {
            useCelsius.toggle()
        } label: {
            HStack(spacing: 4) {
                Text("°")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(useCelsius ? "C" : "F")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .frame(minWidth: 18, alignment: .center)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background {
                Capsule()
                    .fill(Self.chromeFill)
                    .overlay(
                        Capsule()
                            .strokeBorder(Self.chromeStroke, lineWidth: 1.25)
                    )
            }
            .shadow(
                color: Self.chromeButtonShadow.color,
                radius: Self.chromeButtonShadow.radius,
                y: Self.chromeButtonShadow.y
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(useCelsius ? "Use Fahrenheit" : "Use Celsius")
    }

    private var showLoadFailurePlaceholder: Bool {
        errorMessage != nil && weatherData.isEmpty && !isLoading
    }

    private var loadFailurePlaceholder: some View {
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

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView(
                    weatherCode: currentWeatherCode,
                    isDay: currentIsDay,
                    temperatureF: currentTemp
                )
                .animation(.easeInOut(duration: 0.85), value: currentWeatherCode)
                .animation(.easeInOut(duration: 0.85), value: currentIsDay)
                .animation(.easeInOut(duration: 0.85), value: currentTemp)
                .edgesIgnoringSafeArea(.all)

                if showLoadFailurePlaceholder {
                    loadFailurePlaceholder
                } else {
                ScrollView {
                    VStack(spacing: 16) {
                        CityTextView(cityName: storedCityName)

                        Group {
                            if weatherData.isEmpty && isLoading && errorMessage == nil {
                                VStack(spacing: 18) {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Updating weather…")
                                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.92))
                                }
                                .frame(minHeight: 220)
                                .frame(maxWidth: .infinity)
                            } else if !weatherData.isEmpty {
                                MainWeatherView(
                                    imageName: mainHeroSymbol,
                                    temperature: displayTemperature(fahrenheit: currentTemp),
                                    unit: unitSuffix,
                                    conditionText: WeatherService.conditionDescription(
                                        for: currentWeatherCode,
                                        isDay: currentIsDay
                                    ),
                                    feelsLike: nil
                                )

                                WeatherForecastStripsPanel {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if !hourlySlice24.isEmpty {
                                            GeometryReader { geo in
                                                let columnWidth = Self.hourlyColumnWidth(containerWidth: geo.size.width)
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: Self.hourlyColumnSpacing) {
                                                        ForEach(hourlySlice24) { hour in
                                                            hourlyForecastColumn(hour: hour, cellWidth: columnWidth)
                                                        }
                                                    }
                                                    .padding(.horizontal, Self.hourlyStripHorizontalPadding)
                                                    .padding(.vertical, Self.forecastStripHStackVerticalPadding)
                                                    .frame(height: geo.size.height, alignment: .top)
                                                }
                                            }
                                            .frame(height: Self.hourlyStripRowHeight)
                                        }

                                        GeometryReader { geo in
                                            let dayColumnWidth = Self.dailyColumnWidth(containerWidth: geo.size.width)
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: Self.dailyColumnSpacing) {
                                                    ForEach(weatherData) { weather in
                                                        Button {
                                                            withAnimation(.spring(response: 0.48, dampingFraction: 0.86, blendDuration: 0.2)) {
                                                                dayDetailSelection = weather
                                                            }
                                                        } label: {
                                                            WeatherDayView(
                                                                dayOfWeek: weather.dayOfWeek,
                                                                imageName: weather.imageName,
                                                                highTemperature: displayTemperature(fahrenheit: weather.temperature),
                                                                lowTemperature: weather.lowTempF.map { displayTemperature(fahrenheit: $0) },
                                                                unit: unitSuffix,
                                                                stripCompact: true
                                                            )
                                                            .frame(width: dayColumnWidth)
                                                        }
                                                        .buttonStyle(DayCardPressStyle())
                                                    }
                                                }
                                                .padding(.horizontal, Self.dailyStripHorizontalPadding)
                                                .padding(.vertical, Self.forecastStripHStackVerticalPadding)
                                                .frame(height: geo.size.height, alignment: .bottom)
                                            }
                                        }
                                        .frame(height: Self.dailyStripRowHeight)
                                    }
                                }
                                .padding(.horizontal, 20)

                                weatherStatGrid
                            }
                        }

                        if let lastUpdatedLabel {
                            Text(lastUpdatedLabel)
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
                    // Clear fixed °C/°F control when scrolling to end.
                    .padding(.bottom, 80)
                }
                .refreshable {
                    await loadWeather(isManualRetry: false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !showLoadFailurePlaceholder {
                    unitToggleFloating
                        .padding(.trailing, 14)
                        .padding(.bottom, 10)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCitySearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .shadow(
                                color: Self.chromeButtonShadow.color,
                                radius: Self.chromeButtonShadow.radius,
                                y: Self.chromeButtonShadow.y
                            )
                    }
                    .accessibilityLabel("Search city")
                }
            }
            .sheet(isPresented: $showCitySearch) {
                CitySearchView { place in
                    storedCityName = "\(place.name), \(place.country)"
                    storedLatitudeString = String(place.latitude)
                    storedLongitudeString = String(place.longitude)
                    storedTimezone = place.timezone
                }
            }
            .sheet(item: $dayDetailSelection) { selected in
                DayDetailView(
                    summary: selected,
                    hourly: hourlyItems(forDayId: selected.id),
                    timeZoneIdentifier: storedTimezone,
                    useCelsius: useCelsius,
                    cityName: storedCityName,
                    humidityPercent: humidityPercent,
                    windSpeedMph: windSpeedMph,
                    windDirectionDegrees: windDirectionDegrees,
                    longDateString: WeatherDateFormatting.longDateLabel(dayId: selected.id, timeZoneIdentifier: storedTimezone)
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .task(id: "\(storedLatitudeString)|\(storedLongitudeString)|\(storedTimezone)") {
                await loadWeather(isManualRetry: false)
            }
        }
        .overlay(alignment: .top) {
            weatherTopFetchControl
                .padding(.top, 0)
        }
    }
    
    private func loadWeather(isManualRetry: Bool) async {
        if !isManualRetry {
            errorMessage = nil
        }
        isLoading = true
        defer {
            isLoading = false
            pendingManualRetryProgress = false
        }
        do {
            let forecast = try await WeatherService.fetchForecast(
                latitude: selectedLatitude,
                longitude: selectedLongitude,
                timeZoneIdentifier: storedTimezone
            )
            currentTemp = forecast.currentTempF
            currentWeatherCode = forecast.currentCode
            currentIsDay = forecast.currentIsDay
            apparentTempF = forecast.apparentTempF
            humidityPercent = forecast.relativeHumidityPercent
            precipitationMm = forecast.precipitationMm
            windSpeedMph = forecast.windSpeedMph
            windDirectionDegrees = forecast.windDirectionDegrees
            hourlyForecast = forecast.hourly
            weatherData = forecast.daily.map { item in
                WeatherDay(
                    id: item.id,
                    dayOfWeek: item.weekdayAbbrev,
                    imageName: WeatherService.symbolName(for: item.weatherCode, isDay: true),
                    weatherCode: item.weatherCode,
                    temperature: item.highTempF,
                    lowTempF: item.lowTempF,
                    precipitationProbabilityMax: item.precipitationProbabilityMax,
                    sunrise: item.sunrise,
                    sunset: item.sunset
                )
            }
            lastUpdatedAt = Date()
            loadFailedOffline = false
            errorMessage = nil
        } catch {
            if error is CancellationError { return }
            if (error as? URLError)?.code == .cancelled { return }
            let offline = WeatherService.isLikelyConnectivityFailure(error)
            loadFailedOffline = offline
            errorMessage = offline
                ? "No internet connection."
                : "Couldn’t load weather. Check your connection and try again."
        }
    }
}


#Preview {
    WeatherDashboardView()
}
