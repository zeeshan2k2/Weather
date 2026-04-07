//
//  ContentView.swift
//  Weather
//
//  Created by Zeeshan Waheed on 24/03/2026.
//

import SwiftUI

struct day: Identifiable, Hashable {
    let id: String
    var dayOfWeek: String
    var imageName: String
    var weatherCode: Int
    /// Daily high (°F); UI still uses this as the main number on the strip.
    var temperature: Int
    var lowTempF: Int?
    var precipitationProbabilityMax: Int?
    var sunrise: String?
    var sunset: String?
}

struct ContentView: View {
    
    // Views are recreated on state changes, so local variables don’t persist.
    // @State stores the value outside the view and keeps it alive across re-renders.
    @AppStorage("weatherCityName") private var storedCityName = "Cupertino, CA"
    @AppStorage("weatherLatitude") private var storedLatitudeString = "37.3230"
    @AppStorage("weatherLongitude") private var storedLongitudeString = "-122.0322"
    @AppStorage("weatherTimezone") private var storedTimezone = "America/Los_Angeles"
    
    @State private var showCitySearch = false
    @State private var weatherData: [day] = []
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
    @State private var dayDetailSelection: day?
    
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

    private func longDateLabel(dayId: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: storedTimezone) ?? .gmt
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dayId) else { return "" }
        let out = DateFormatter()
        out.timeZone = TimeZone(identifier: storedTimezone) ?? .gmt
        out.dateFormat = "EEEE, MMMM d"
        return out.string(from: date)
    }

    private var lastUpdatedLabel: String? {
        guard let lastUpdatedAt else { return nil }
        return "Last updated \(lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private func formattedHourLabel(timeISO: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: storedTimezone) ?? .gmt
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm"
        guard let date = parser.date(from: timeISO) else { return "--" }
        let out = DateFormatter()
        out.timeZone = TimeZone(identifier: storedTimezone) ?? .gmt
        out.dateFormat = "h a"
        return out.string(from: date)
    }
    
    /// Rough day/night for hourly icons (local solar day proxy).
    private func hourlyIsDaylight(timeISO: String) -> Bool {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: storedTimezone) ?? .gmt
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm"
        guard let date = parser.date(from: timeISO) else { return currentIsDay }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: storedTimezone) ?? .gmt
        let hour = calendar.component(.hour, from: date)
        return hour >= 7 && hour < 19
    }
    
    private var selectedLatitude: Double {
        Double(storedLatitudeString) ?? 37.3230
    }
    
    private var selectedLongitude: Double {
        Double(storedLongitudeString) ?? -122.0322
    }

    private func windDirectionAbbrev(degrees: Int?) -> String? {
        guard let d = degrees else { return nil }
        let names = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        var x = Double(d).truncatingRemainder(dividingBy: 360)
        if x < 0 { x += 360 }
        let idx = Int((x + 11.25) / 22.5) % 16
        return names[idx]
    }

    private func precipitationDisplay(mm: Double?) -> String {
        guard let mm, mm >= 0 else { return "—" }
        if mm < 0.02 { return "None" }
        if mm < 1 { return String(format: "%.1f mm", mm) }
        return String(format: "%.0f mm", mm)
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
            if let dir = windDirectionAbbrev(degrees: windDirectionDegrees) {
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
                value: precipitationDisplay(mm: precipitationMm)
            )
        }
        .padding(.horizontal, 20)
    }

    private static let chromeButtonShadow = (color: Color.black.opacity(0.42), radius: CGFloat(5), y: CGFloat(2))
    /// Frosted bubble — opaque enough to read on bright sky gradients.
    private static let chromeFill = Color.white.opacity(0.42)
    private static let chromeStroke = Color.white.opacity(0.55)

    /// 44×44 bubble for floating controls (e.g. reload). Toolbar search keeps the system bar-button chrome.
    private func weatherBubbleCircleButton(
        systemName: String,
        accessibilityLabel label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(Self.chromeFill)
                        .overlay(Circle().strokeBorder(Self.chromeStroke, lineWidth: 1.25))
                }
                .clipShape(Circle())
                .shadow(
                    color: Self.chromeButtonShadow.color,
                    radius: Self.chromeButtonShadow.radius,
                    y: Self.chromeButtonShadow.y
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
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
                ScrollView {
                    VStack(spacing: 16) {
                        CityTextView(cityName: storedCityName)

                        Group {
                            if weatherData.isEmpty {
                                VStack(spacing: 18) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                        Text("Updating weather…")
                                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.92))
                                    }
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

                                if !hourlySlice24.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 18) {
                                            ForEach(hourlySlice24) { hour in
                                                VStack(spacing: 6) {
                                                    Text(formattedHourLabel(timeISO: hour.timeISO))
                                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                                        .foregroundStyle(.white.opacity(0.85))
                                                        .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                                                    Image(systemName: WeatherService.symbolName(
                                                        for: hour.weatherCode,
                                                        isDay: hourlyIsDaylight(timeISO: hour.timeISO)
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
                                                }
                                                .frame(minWidth: 52)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                    }
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
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
                                                    unit: unitSuffix
                                                )
                                            }
                                            .buttonStyle(DayCardPressStyle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                }

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
                    await loadWeather()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .overlay(alignment: .top) {
                if errorMessage != nil {
                    weatherBubbleCircleButton(
                        systemName: "arrow.clockwise",
                        accessibilityLabel: "Retry loading weather"
                    ) {
                        Task { await loadWeather() }
                    }
                    .padding(.top, -40)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                unitToggleFloating
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
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
                    longDateString: longDateLabel(dayId: selected.id)
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .task(id: "\(storedLatitudeString)|\(storedLongitudeString)|\(storedTimezone)") {
                await loadWeather()
            }
        }
    }
    
    private func loadWeather() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
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
                day(
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
        } catch {
            if error is CancellationError { return }
            if (error as? URLError)?.code == .cancelled { return }
            errorMessage = "Couldn’t load weather. Check your connection and try again."
        }
    }
}

struct WeatherStatTile: View {

    var icon: String
    var title: String
    var value: String

    private var cellShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(width: 18, alignment: .center)
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.28), radius: 2, y: 1)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(12)
        .background {
            cellShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            cellShape
                .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
        }
    }
}

struct WeatherDayView: View {
    
    var dayOfWeek: String
    var imageName: String
    /// Already converted for display (°C or °F).
    var highTemperature: Int
    var lowTemperature: Int?
    var unit: String = "F"
    
    private var cellShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
    }
    
    var body: some View {
        VStack(spacing: 5) {
            Text(dayOfWeek)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
            
            Image(systemName: imageName)
                .symbolRenderingMode(.multicolor)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 38)
                .foregroundStyle(.white)
            
            Group {
                if let lowTemperature {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(highTemperature)°\(unit)")
                            .font(.system(size: 21, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                        Text("\(lowTemperature)°\(unit)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                    }
                } else {
                    Text("\(highTemperature)°\(unit)")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background {
            cellShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            cellShape
                .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
        }
    }
}

// MARK: - Day card interaction

private struct DayCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.64, blendDuration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Day detail sheet

struct DayDetailView: View {

    let summary: day
    let hourly: [HourlyForecastItem]
    let timeZoneIdentifier: String
    let useCelsius: Bool
    let cityName: String
    let humidityPercent: Int?
    let windSpeedMph: Double?
    let windDirectionDegrees: Int?
    let longDateString: String

    @Environment(\.dismiss) private var dismiss
    @State private var heroAppeared = false

    private var unit: String { useCelsius ? "C" : "F" }

    private func displayTemp(_ fahrenheit: Int) -> Int {
        useCelsius ? Int((Double(fahrenheit) - 32) * 5 / 9) : fahrenheit
    }

    private func formattedHourLabel(timeISO: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm"
        guard let date = parser.date(from: timeISO) else { return "--" }
        let out = DateFormatter()
        out.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        out.dateFormat = "h a"
        return out.string(from: date)
    }

    private func hourlyIsDaylight(timeISO: String) -> Bool {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm"
        guard let date = parser.date(from: timeISO) else { return true }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        let hour = calendar.component(.hour, from: date)
        return hour >= 7 && hour < 19
    }

    private func formatSunEvent(_ iso: String?) -> String {
        guard let iso else { return "—" }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm"
        guard let date = parser.date(from: iso) else { return "—" }
        let out = DateFormatter()
        out.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        out.dateFormat = "h:mm a"
        return out.string(from: date)
    }

    private func windDirectionAbbrev(degrees: Int?) -> String? {
        guard let d = degrees else { return nil }
        let names = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        var x = Double(d).truncatingRemainder(dividingBy: 360)
        if x < 0 { x += 360 }
        let idx = Int((x + 11.25) / 22.5) % 16
        return names[idx]
    }

    private var conditionSummary: String {
        WeatherService.conditionDescription(for: summary.weatherCode, isDay: true)
    }

    private var detailSymbol: String {
        WeatherService.symbolName(for: summary.weatherCode, isDay: true)
    }

    private var glassShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }

    /// Hide the whole block when there’s nothing meaningful to show (0% rain is omitted like a clear day).
    private var atAGlanceSectionVisible: Bool {
        if let p = summary.precipitationProbabilityMax, p > 0 { return true }
        if humidityPercent != nil { return true }
        if windSpeedMph != nil { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundView(
                    weatherCode: summary.weatherCode,
                    isDay: true,
                    temperatureF: summary.temperature
                )
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(spacing: 18) {
                            Text(cityName)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.78))
                                .frame(maxWidth: .infinity)

                            Text(longDateString)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.28), radius: 4, y: 2)
                                .frame(maxWidth: .infinity)

                            Text(summary.dayOfWeek)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(.white.opacity(0.65))
                                .frame(maxWidth: .infinity)

                            Image(systemName: detailSymbol)
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 118, height: 118)
                                .scaleEffect(heroAppeared ? 1 : 0.62)
                                .opacity(heroAppeared ? 1 : 0)
                                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                                .frame(maxWidth: .infinity)

                            Text(conditionSummary)
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.22), radius: 3, y: 2)
                                .frame(maxWidth: .infinity)

                            HStack(alignment: .top, spacing: 28) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("High")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.65))
                                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                                        Text("\(displayTemp(summary.temperature))°")
                                            .font(.system(size: 54, weight: .semibold, design: .rounded))
                                        Text(unit)
                                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                                            .baselineOffset(6)
                                    }
                                    .foregroundStyle(.white)
                                }
                                if let lowF = summary.lowTempF {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Low")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.65))
                                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                                            Text("\(displayTemp(lowF))°")
                                                .font(.system(size: 40, weight: .semibold, design: .rounded))
                                            Text(unit)
                                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                                .baselineOffset(4)
                                        }
                                        .foregroundStyle(.white.opacity(0.92))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                        }
                        .padding(.top, 8)

                        if atAGlanceSectionVisible {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("At a glance")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .textCase(.uppercase)
                                    .tracking(0.8)

                                VStack(alignment: .leading, spacing: 16) {
                                    if let precip = summary.precipitationProbabilityMax, precip > 0 {
                                        dayDetailMetric(icon: "drop.fill", title: "Precipitation chance", value: "\(precip)%")
                                    }
                                    if let humidityPercent {
                                        dayDetailMetric(icon: "humidity.fill", title: "Humidity (now)", value: "\(humidityPercent)%")
                                    }
                                    if let mph = windSpeedMph {
                                        let speed = String(format: "%.0f mph", mph)
                                        let dir = windDirectionAbbrev(degrees: windDirectionDegrees).map { " \($0)" } ?? ""
                                        dayDetailMetric(icon: "wind", title: "Wind (now)", value: "\(speed)\(dir)")
                                    }
                                }
                                .padding(22)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background {
                                    glassShape
                                        .fill(Color.white.opacity(0.16))
                                        .overlay(glassShape.strokeBorder(Color.white.opacity(0.38), lineWidth: 1))
                                }
                                .shadow(color: .black.opacity(0.18), radius: 16, y: 6)

                                if humidityPercent != nil || windSpeedMph != nil {
                                    Text("Current wind and humidity describe conditions at the last update, not the whole day.")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Hourly")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .textCase(.uppercase)
                                .tracking(0.8)

                            if hourly.isEmpty {
                                Text("No hourly breakdown for this day.")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.75))
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 18) {
                                        ForEach(hourly) { hour in
                                            VStack(spacing: 8) {
                                                Text(formattedHourLabel(timeISO: hour.timeISO))
                                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                                    .foregroundStyle(.white.opacity(0.88))
                                                Image(systemName: WeatherService.symbolName(
                                                    for: hour.weatherCode,
                                                    isDay: hourlyIsDaylight(timeISO: hour.timeISO)
                                                ))
                                                .symbolRenderingMode(.multicolor)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 32, height: 32)
                                                Text("\(displayTemp(hour.tempF))°\(unit)")
                                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                                    .foregroundStyle(.white)
                                            }
                                            .frame(minWidth: 56)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                }
                            }
                        }

                        HStack(spacing: 14) {
                            dayDetailSunPill(title: "Sunrise", time: formatSunEvent(summary.sunrise), icon: "sunrise.fill")
                            dayDetailSunPill(title: "Sunset", time: formatSunEvent(summary.sunset), icon: "sunset.fill")
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26, weight: .regular))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white, .white.opacity(0.32))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.72, blendDuration: 0.2)) {
                heroAppeared = true
            }
        }
    }
}

private func dayDetailMetric(icon: String, title: String, value: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .frame(width: 22)
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        Spacer(minLength: 0)
    }
}

private func dayDetailSunPill(title: String, time: String, icon: String) -> some View {
    let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    return HStack(spacing: 10) {
        Image(systemName: icon)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white.opacity(0.95))
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
            Text(time)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        Spacer(minLength: 0)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background {
        shape
            .fill(Color.white.opacity(0.14))
            .overlay(shape.strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
    }
}

struct BackgroundView: View {
    
    var weatherCode: Int
    var isDay: Bool
    var temperatureF: Int
    
    var body: some View {
        // adding gradients — driven by condition, sun/moon, and temperature (see WeatherSkyStyle).
        let colors = WeatherSkyStyle.gradientColors(
            weatherCode: weatherCode,
            isDay: isDay,
            tempFahrenheit: temperatureF
        )
        ContainerRelativeShape()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea()
    }
}

struct CityTextView: View {
    
    var cityName: String
    
    var body: some View {
        Text(cityName)
            .font(.system(size: 30, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
            .padding()
    }
}

struct MainWeatherView: View {
    
    var imageName: String
    var temperature: Int
    var unit: String = "F"
    var conditionText: String = ""
    /// Display-unit “feels like” (already converted); same scale as `temperature`.
    var feelsLike: Int? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: imageName)
                .renderingMode(.original)
            // almost always have to use the resizable
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)

            // Single block so spacing is even; large temp font still carries extra
            // line metrics below the digits — trim that so condition sits closer.
            VStack(spacing: 6) {
                Text("\(temperature)°\(unit)")
                    .font(.system(size: 68, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                    .lineLimit(1)
                    .padding(.bottom, -18)

                if !conditionText.isEmpty {
                    Text(conditionText)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                }

                if let feelsLike {
                    Text("Feels like \(feelsLike)°\(unit)")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                }
            }
        }
        .padding(.bottom, 16)
    }
}


#Preview {
    ContentView()
}
