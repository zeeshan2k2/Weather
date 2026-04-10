
import SwiftUI

/// Palette / hierarchy for weather metric icons (`thermometer.medium`, `humidity.fill`, `wind`, `drop.fill`).
enum WeatherMetricIconStyle: Equatable {
    case feelsLike
    case humidity
    case wind
    case precipitation
}

/// Matches previous sRGB values via `Color(hex:)` from `Color+Hex.swift`.
private enum WeatherMetricIconPalette {
    /// Thermometer “mercury” (was ~#D1332E).
    static let mercuryRed = Color(hex: "D1332E")
    /// Deeper blue — precipitation `drop.fill` (was ~#61ADFA).
    static let precipitationDropBlue = Color(hex: "61ADFA")
    /// Lighter blue — humidity droplet (was ~#94D1FA).
    static let humidityDropBlue = Color(hex: "94D1FA")
}

struct WeatherMetricSymbolImage: View {
    let systemName: String
    var size: CGFloat = 14
    var weight: Font.Weight = .semibold
    let style: WeatherMetricIconStyle

    var body: some View {
        let font = Font.system(size: size, weight: weight)
        switch style {
        case .feelsLike:
            Image(systemName: systemName)
                .font(font)
                .symbolRenderingMode(.palette)
                .foregroundStyle(WeatherMetricIconPalette.mercuryRed, Color.white.opacity(0.82))
        case .humidity:
            Image(systemName: systemName)
                .font(font)
                .symbolRenderingMode(.palette)
                .foregroundStyle(WeatherMetricIconPalette.humidityDropBlue, Color.white)
        case .wind:
            Image(systemName: systemName)
                .font(font)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.88))
        case .precipitation:
            Image(systemName: systemName)
                .font(font)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(WeatherMetricIconPalette.precipitationDropBlue)
        }
    }
}
