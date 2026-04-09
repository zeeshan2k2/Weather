//
//  DayDetailScreenViews.swift
//  Weather
//
//  Day-detail–only UI pieces (hero, metrics, hourly strip, sun pills).
//

import SwiftUI

// MARK: - Hero

struct DayDetailHeroHeader: View {
    let summary: WeatherDay
    let cityName: String
    let longDateString: String
    let unit: String
    var displayTemp: (Int) -> Int
    var heroAppeared: Bool

    private var conditionSummary: String {
        WeatherPresentation.conditionDescription(for: summary.weatherCode, isDay: true)
    }

    private var detailSymbol: String {
        WeatherPresentation.symbolName(for: summary.weatherCode, isDay: true)
    }

    var body: some View {
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
    }
}

// MARK: - At a glance

struct DayDetailAtAGlanceSection: View {
    let summary: WeatherDay
    let humidityPercent: Int?
    let windSpeedMph: Double?

    private var glassShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("At a glance")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .textCase(.uppercase)
                .tracking(0.8)

            VStack(alignment: .leading, spacing: 16) {
                if let precip = summary.precipitationProbabilityMax {
                    DayDetailMetricRow(icon: "drop.fill", title: "Precipitation chance", value: "\(precip)%")
                }
                if let humidityPercent {
                    DayDetailMetricRow(icon: "humidity.fill", title: "Humidity (now)", value: "\(humidityPercent)%")
                }
                if let mph = windSpeedMph {
                    DayDetailMetricRow(icon: "wind", title: "Wind (now)", value: String(format: "%.0f mph", mph))
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
}

struct DayDetailMetricRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
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
}

// MARK: - Hourly

/// Matches dashboard hourly strip: exactly five columns visible; additional hours scroll horizontally.
private enum DayDetailHourlyStripLayout {
    static let visibleColumnCount: CGFloat = 5
    static let columnSpacing: CGFloat = 12
    static let horizontalPadding: CGFloat = 6
    static let rowHeight: CGFloat = 96
    static let verticalPadding: CGFloat = 4
    /// Trailing inset for `StripScrollHintChevron` from the day-detail column’s outer edge (dashboard uses 5).
    static let scrollHintTrailingMargin: CGFloat = 10

    static func columnWidth(containerWidth: CGFloat) -> CGFloat {
        let inner = containerWidth - horizontalPadding * 2
        let gaps = columnSpacing * (visibleColumnCount - 1)
        let raw = (inner - gaps) / visibleColumnCount
        return max(44, floor(raw))
    }
}

struct DayDetailHourlySection: View {
    let hourly: [HourlyForecastItem]
    let timeZoneIdentifier: String
    let unit: String
    var displayTemp: (Int) -> Int
    /// Same idea as dashboard: inset of scroll content so the chevron’s 5pt margin is from the **outer** column edge.
    var parentHorizontalContentInset: CGFloat = 0

    var body: some View {
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
                ZStack(alignment: .trailing) {
                    GeometryReader { geo in
                        let cellWidth = DayDetailHourlyStripLayout.columnWidth(containerWidth: geo.size.width)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DayDetailHourlyStripLayout.columnSpacing) {
                                ForEach(hourly) { hour in
                                    hourlyColumn(hour: hour, cellWidth: cellWidth)
                                }
                            }
                            .padding(.horizontal, DayDetailHourlyStripLayout.horizontalPadding)
                            .padding(.vertical, DayDetailHourlyStripLayout.verticalPadding)
                            .frame(height: geo.size.height, alignment: .top)
                        }
                    }
                    StripScrollHintChevron(
                        isVisible: hourly.count > Int(DayDetailHourlyStripLayout.visibleColumnCount),
                        parentHorizontalContentInset: parentHorizontalContentInset,
                        trailingMarginFromOuter: DayDetailHourlyStripLayout.scrollHintTrailingMargin
                    )
                }
                .frame(height: DayDetailHourlyStripLayout.rowHeight)
            }
        }
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
                    fallbackIsDay: true
                )
            ))
            .symbolRenderingMode(.multicolor)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .foregroundStyle(.white)
            Text("\(displayTemp(hour.tempF))°\(unit)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(width: cellWidth)
    }
}

// MARK: - Sunrise / sunset

struct DayDetailSunriseSunsetRow: View {
    let sunriseISO: String?
    let sunsetISO: String?
    let timeZoneIdentifier: String

    var body: some View {
        HStack(spacing: 14) {
            DayDetailSunEventPill(
                title: "Sunrise",
                time: WeatherDateFormatting.formattedSunEvent(iso: sunriseISO, timeZoneIdentifier: timeZoneIdentifier),
                icon: "sunrise.fill"
            )
            DayDetailSunEventPill(
                title: "Sunset",
                time: WeatherDateFormatting.formattedSunEvent(iso: sunsetISO, timeZoneIdentifier: timeZoneIdentifier),
                icon: "sunset.fill"
            )
        }
    }
}

struct DayDetailSunEventPill: View {
    let title: String
    let time: String
    let icon: String

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 10) {
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
}
