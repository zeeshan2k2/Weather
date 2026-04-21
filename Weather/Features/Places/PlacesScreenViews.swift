import SwiftUI

private struct PlacesCardSkeletonView: View {
    private func bone(_ opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color.white.opacity(opacity))
    }

    private var skeletonLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    bone(0.17)
                        .frame(maxWidth: .infinity)
                        .frame(height: 22)
                        .padding(.trailing, 36)
                    bone(0.13)
                        .frame(width: 132, height: 22)
                    bone(0.11)
                        .frame(width: 96, height: 14)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 10) {
                    bone(0.14)
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    bone(0.15)
                        .frame(width: 64, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            Spacer(minLength: 18)

            HStack(alignment: .bottom) {
                bone(0.14)
                    .frame(width: 128, height: 17)
                Spacer(minLength: 8)
                bone(0.12)
                    .frame(width: 108, height: 15)
            }
        }
    }

    var body: some View {
        skeletonLayout
            .opacity(0.92)
    }
}

struct PlacesWeatherLocationCard: View {
    let title: String
    let subtitle: String
    var snapshot: PlacesForecastSnapshot?
    var isLoading: Bool
    var useCelsius: Bool
    var isSelected: Bool

    var offlineWithNoData: Bool = false

    var usedStaleCache: Bool = false

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }

    private var chromeGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "1E2F45"),
                Color(hex: "121B28")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func weatherGradient(for snapshot: PlacesForecastSnapshot) -> LinearGradient {
        LinearGradient(
            colors: WeatherSkyStyle.gradientColors(
                weatherCode: snapshot.code,
                isDay: snapshot.isDay,
                tempFahrenheit: snapshot.currentTempF
            ),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var topWashGradient: LinearGradient {
        let highlight = snapshot.map { $0.isDay == true ? 0.14 : 0.08 } ?? 0.06
        return LinearGradient(
            colors: [Color.white.opacity(highlight), Color.clear],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.42)
        )
    }

    private var conditionLabel: String {
        guard let s = snapshot else {
            if isLoading { return "Loading…" }
            if offlineWithNoData { return "No internet connection" }
            return "Forecast unavailable"
        }
        return WeatherPresentation.conditionDescription(for: s.code, isDay: s.isDay)
    }

    private var symbolName: String {
        guard let s = snapshot else { return "cloud.fill" }
        return WeatherPresentation.symbolName(for: s.code, isDay: s.isDay)
    }

    private var tempDisplay: String {
        guard let s = snapshot else { return "—" }
        let v = DashboardTemperature.display(fahrenheit: s.currentTempF, useCelsius: useCelsius)
        return "\(v)°"
    }

    private var highLowDisplay: String {
        guard let s = snapshot else { return " " }
        let h = DashboardTemperature.display(fahrenheit: s.highF, useCelsius: useCelsius)
        let l = DashboardTemperature.display(fahrenheit: s.lowF, useCelsius: useCelsius)
        let u = useCelsius ? "C" : "F"
        return "H:\(h)°\(u)  L:\(l)°\(u)"
    }

    var body: some View {
        ZStack {
            cardShape.fill(chromeGradient)

            if let s = snapshot {
                cardShape
                    .fill(weatherGradient(for: s))
            }

            topWashGradient
                .clipShape(cardShape)

            Group {
                if isLoading && snapshot == nil {
                    PlacesCardSkeletonView()
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(title)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(subtitle)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.78))
                                        .lineLimit(1)
                                    if usedStaleCache {
                                        Text("Saved forecast — connect to update")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.55))
                                            .lineLimit(1)
                                    }
                                }
                            }

                            Spacer(minLength: 8)

                            VStack(alignment: .trailing, spacing: 6) {
                                WeatherSkyConditionSymbol.image(systemName: symbolName)
                                    .font(.system(size: 26, weight: .medium))

                                Text(tempDisplay)
                                    .font(.system(size: 42, weight: .thin, design: .rounded))
                                    .foregroundStyle(.white)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                        }

                        Spacer(minLength: 18)

                        HStack(alignment: .bottom) {
                            Text(conditionLabel)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            if snapshot != nil {
                                Text(highLowDisplay)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.88))
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .overlay {
            cardShape
                .strokeBorder(
                    isSelected ? Color.white.opacity(0.55) : Color.white.opacity(0.22),
                    lineWidth: isSelected ? 2.5 : 1
                )
        }
        .shadow(color: .black.opacity(0.28), radius: 14, y: 6)
    }
}
