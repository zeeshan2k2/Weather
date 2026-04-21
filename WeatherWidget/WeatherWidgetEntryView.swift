import SwiftUI
import WidgetKit

struct WeatherWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var widgetMargins
    var entry: WeatherWidgetEntry

    private var basePalette: [Color] {
        WeatherSkyStyle.gradientColors(
            weatherCode: entry.weatherCode,
            isDay: entry.isDay,
            tempFahrenheit: max(entry.temperatureF, 32)
        )
    }

    private var widgetAtmosphereBackground: some View {
        ZStack {
            LinearGradient(
                colors: basePalette,
                startPoint: .top,
                endPoint: .bottom
            )
            LinearGradient(
                colors: [Color.white.opacity(entry.isDay ? 0.12 : 0.06), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.45)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var body: some View {
        Group {
            if let error = entry.errorMessage {
                WeatherWidgetErrorLayout(entry: entry, message: error)
            } else if family == .systemMedium {
                WeatherWidgetMediumLayout(entry: entry)
            } else {
                WeatherWidgetSmallLayout(entry: entry)
            }
        }
        .padding(widgetMargins)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            widgetAtmosphereBackground
        }
    }
}

private struct WeatherWidgetSmallLayout: View {
    let entry: WeatherWidgetEntry

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ZStack(alignment: .bottomLeading) {
                Image(systemName: entry.symbolName)
                    .font(.system(size: 72, weight: .ultraLight))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.white.opacity(0.16))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .offset(x: 10, y: 4)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.cityName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(4)
                        .minimumScaleFactor(0.78)
                        .shadow(color: .black.opacity(0.22), radius: 2, y: 1)

                    Spacer(minLength: 8)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(entry.tempDisplay(entry.temperatureF))°")
                                .font(.system(size: 35, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.85)
                                .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                            WeatherWidgetMulticolorSymbol(systemName: entry.symbolName, font: .system(size: 24, weight: .regular))
                        }
                        Text(entry.conditionText)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.95))
                            .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)

            if let highLow = entry.highLowPair {
                WeatherWidgetDailyHighLowColumn(entry: entry, high: highLow.high, low: highLow.low, compact: true)
            }
        }
    }
}

private struct WeatherWidgetMediumLayout: View {
    let entry: WeatherWidgetEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.cityName)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .shadow(color: .black.opacity(0.22), radius: 2, y: 1)

                if !entry.hourlySlots.isEmpty {
                    WeatherWidgetMediumHourlyStrip(entry: entry)
                        .padding(.top, 8)
                }

                Spacer(minLength: 0)

                Text(entry.conditionText)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 0) {
                VStack(alignment: .trailing, spacing: 4) {
                    WeatherWidgetMulticolorSymbol(systemName: entry.symbolName, font: .system(size: 44, weight: .regular))
                        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                    Text("\(entry.tempDisplay(entry.temperatureF))°")
                        .font(.system(size: 50, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.8)
                        .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                }

                Spacer(minLength: 0)

                WeatherWidgetMediumBottomMeta(entry: entry)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct WeatherWidgetMediumBottomMeta: View {
    let entry: WeatherWidgetEntry

    var body: some View {
        if entry.highLowPair != nil || (entry.latitude != nil && entry.longitude != nil) {
            VStack(alignment: .trailing, spacing: 2) {
                if let highLow = entry.highLowPair {
                    Text("H \(entry.tempDisplay(highLow.high))°  L \(entry.tempDisplay(highLow.low))°")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                        .monospacedDigit()
                        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                }
                if let lat = entry.latitude, let lon = entry.longitude {
                    Text(String(format: "%.2f°, %.2f°", lat, lon))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.22), radius: 1, y: 1)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityCoordinateLabel)
        }
    }

    private var accessibilityCoordinateLabel: String {
        var parts: [String] = []
        if let h = entry.dailyHighTempF, let l = entry.dailyLowTempF {
            parts.append("High \(entry.tempDisplay(h)) degrees \(entry.unitSuffix), low \(entry.tempDisplay(l)) degrees \(entry.unitSuffix)")
        }
        if let lat = entry.latitude, let lon = entry.longitude {
            parts.append("Latitude \(lat), longitude \(lon)")
        }
        return parts.joined(separator: ". ")
    }
}

private struct WeatherWidgetMediumHourlyStrip: View {
    let entry: WeatherWidgetEntry

    var body: some View {
        let slots = Array(entry.hourlySlots.prefix(5))
        return HStack(alignment: .center, spacing: 3) {
            ForEach(slots, id: \.stripIdentifier) { slot in
                VStack(alignment: .center, spacing: 3) {
                    Text(slot.hourLabel)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    WeatherWidgetMulticolorSymbol(systemName: slot.symbolName, font: .system(size: 18, weight: .regular))
                        .frame(maxWidth: .infinity)
                    Text("\(entry.tempDisplay(slot.tempF))°")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next five hours")
    }
}

private struct WeatherWidgetDailyHighLowColumn: View {
    let entry: WeatherWidgetEntry
    let high: Int
    let low: Int
    let compact: Bool

    var body: some View {
        let labelSize: CGFloat = compact ? 7 : 8
        let valueSize: CGFloat = compact ? 11 : 13
        return VStack(alignment: .trailing, spacing: 0) {
            Text("H")
                .font(.system(size: labelSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
            Text("\(entry.tempDisplay(high))°")
                .font(.system(size: valueSize, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
            Text("L")
                .font(.system(size: labelSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .padding(.top, 2)
            Text("\(entry.tempDisplay(low))°")
                .font(.system(size: valueSize, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("High \(entry.tempDisplay(high)) degrees \(entry.unitSuffix), low \(entry.tempDisplay(low)) degrees \(entry.unitSuffix)")
    }
}

private struct WeatherWidgetErrorLayout: View {
    let entry: WeatherWidgetEntry
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.cityName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(3)
            HStack(spacing: 8) {
                WeatherWidgetMulticolorSymbol(systemName: entry.symbolName, font: .body)
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.95))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct WeatherWidgetMulticolorSymbol: View {
    let systemName: String
    let font: Font

    private var isCloudMoon: Bool {
        WeatherPresentation.usesCloudMoonHierarchicalSymbol(systemName: systemName)
    }

    var body: some View {
        Group {
            if isCloudMoon {
                if #available(iOSApplicationExtension 18.0, *) {
                    Image(systemName: systemName)
                        .widgetAccentedRenderingMode(.fullColor)
                        .font(font)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white.opacity(0.95), .white.opacity(0.48))
                } else {
                    Image(systemName: systemName)
                        .font(font)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white.opacity(0.95), .white.opacity(0.48))
                }
            } else if #available(iOSApplicationExtension 18.0, *) {
                Image(systemName: systemName)
                    .widgetAccentedRenderingMode(.fullColor)
                    .font(font)
                    .symbolRenderingMode(.multicolor)
            } else {
                Image(systemName: systemName)
                    .font(font)
                    .symbolRenderingMode(.multicolor)
            }
        }
    }
}
