//
//  DashboardScreenViews.swift
//  Weather
//
//  Dashboard-only UI pieces (failure state, retry, strips, stats).
//

import SwiftUI

// MARK: - Load failure

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

// MARK: - Top retry (error banner slot)

enum DashboardChromeMetrics {
    static let chromeButtonShadow = (color: Color.black.opacity(0.42), radius: CGFloat(5), y: CGFloat(2))
    static let chromeFill = Color.white.opacity(0.42)
    static let chromeStroke = Color.white.opacity(0.55)
    /// Stronger than `chromeFill` so the floating unit pill stays legible on bright sky gradients.
    static let unitToggleCapsuleFill = Color.white.opacity(0.68)
    static let unitToggleCapsuleStroke = Color.white.opacity(0.78)
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

// MARK: - Unit toggle

struct DashboardUnitToggleButton: View {
    @Binding var useCelsius: Bool

    var body: some View {
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
                    .fill(DashboardChromeMetrics.unitToggleCapsuleFill)
                    .overlay(
                        Capsule()
                            .strokeBorder(DashboardChromeMetrics.unitToggleCapsuleStroke, lineWidth: 1.25)
                    )
            }
            .shadow(
                color: DashboardChromeMetrics.chromeButtonShadow.color,
                radius: DashboardChromeMetrics.chromeButtonShadow.radius,
                y: DashboardChromeMetrics.chromeButtonShadow.y
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(useCelsius ? "Use Fahrenheit" : "Use Celsius")
    }
}

// MARK: - Stats grid

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
                value: "\(DashboardTemperature.display(fahrenheit: feelsLikeF, useCelsius: useCelsius))°\(unitSuffix)"
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
                value: DashboardTemperature.precipitationTileValue(mm: precipitationMm, todayChancePercent: todayPrecipitationChance)
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Forecast strips (hourly + daily)

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
        VStack(spacing: 6) {
            Text(WeatherDateFormatting.formattedHourLabel(timeISO: hour.timeISO, timeZoneIdentifier: timeZoneIdentifier))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
            Image(systemName: WeatherPresentation.symbolName(
                for: hour.weatherCode,
                isDay: WeatherDateFormatting.hourlyIsDaylight(
                    timeISO: hour.timeISO,
                    timeZoneIdentifier: timeZoneIdentifier,
                    fallbackIsDay: currentIsDay
                )
            ))
            .symbolRenderingMode(.multicolor)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .foregroundStyle(.white)
            Text("\(displayTemp(hour.tempF))°\(unitSuffix)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(width: cellWidth)
    }
}
