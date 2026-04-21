import SwiftUI

private enum DayDetailViewLayout {

    static let horizontalContentPadding: CGFloat = 24
}

struct DayDetailView: View {

    let summary: WeatherDay
    let hourly: [HourlyForecastItem]
    let timeZoneIdentifier: String
    let useCelsius: Bool
    let cityName: String
    let humidityPercent: Int?
    let windSpeedMph: Double?
    let longDateString: String

    @Environment(\.dismiss) private var dismiss
    @State private var heroAppeared = false

    private var unit: String { useCelsius ? "C" : "F" }

    private func displayTemp(_ fahrenheit: Int) -> Int {
        useCelsius ? Int((Double(fahrenheit) - 32) * 5 / 9) : fahrenheit
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
                        DayDetailHeroHeader(
                            summary: summary,
                            cityName: cityName,
                            longDateString: longDateString,
                            unit: unit,
                            displayTemp: displayTemp,
                            heroAppeared: heroAppeared
                        )

                        if atAGlanceSectionVisible {
                            DayDetailAtAGlanceSection(
                                summary: summary,
                                humidityPercent: humidityPercent,
                                windSpeedMph: windSpeedMph
                            )
                        }

                        DayDetailHourlySection(
                            hourly: hourly,
                            timeZoneIdentifier: timeZoneIdentifier,
                            unit: unit,
                            displayTemp: displayTemp,
                            parentHorizontalContentInset: DayDetailViewLayout.horizontalContentPadding
                        )

                        DayDetailSunriseSunsetRow(
                            sunriseISO: summary.sunrise,
                            sunsetISO: summary.sunset,
                            timeZoneIdentifier: timeZoneIdentifier
                        )
                    }
                    .padding(.horizontal, DayDetailViewLayout.horizontalContentPadding)
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
