
import SwiftUI

struct DayDetailView: View {

    let summary: WeatherDay
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

    private var conditionSummary: String {
        WeatherService.conditionDescription(for: summary.weatherCode, isDay: true)
    }

    private var detailSymbol: String {
        WeatherService.symbolName(for: summary.weatherCode, isDay: true)
    }

    private var glassShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }

    private var atAGlanceSectionVisible: Bool {
        if summary.precipitationProbabilityMax != nil { return true }
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
                                    if let precip = summary.precipitationProbabilityMax {
                                        dayDetailMetric(icon: "drop.fill", title: "Precipitation chance", value: "\(precip)%")
                                    }
                                    if let humidityPercent {
                                        dayDetailMetric(icon: "humidity.fill", title: "Humidity (now)", value: "\(humidityPercent)%")
                                    }
                                    if let mph = windSpeedMph {
                                        let speed = String(format: "%.0f mph", mph)
                                        let dir = WeatherService.windDirectionAbbreviation(degrees: windDirectionDegrees).map { " \($0)" } ?? ""
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
                                                Text(WeatherDateFormatting.formattedHourLabel(timeISO: hour.timeISO, timeZoneIdentifier: timeZoneIdentifier))
                                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                                    .foregroundStyle(.white.opacity(0.88))
                                                Image(systemName: WeatherService.symbolName(
                                                    for: hour.weatherCode,
                                                    isDay: WeatherDateFormatting.hourlyIsDaylight(timeISO: hour.timeISO, timeZoneIdentifier: timeZoneIdentifier, fallbackIsDay: true)
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
                            dayDetailSunPill(title: "Sunrise", time: WeatherDateFormatting.formattedSunEvent(iso: summary.sunrise, timeZoneIdentifier: timeZoneIdentifier), icon: "sunrise.fill")
                            dayDetailSunPill(title: "Sunset", time: WeatherDateFormatting.formattedSunEvent(iso: summary.sunset, timeZoneIdentifier: timeZoneIdentifier), icon: "sunset.fill")
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
