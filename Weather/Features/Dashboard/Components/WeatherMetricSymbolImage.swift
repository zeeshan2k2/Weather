import SwiftUI

enum WeatherMetricIconStyle: Equatable {
    case feelsLike
    case humidity
    case wind
    case precipitation
}

private enum WeatherMetricIconPalette {

    static let mercuryRed = Color(hex: "D1332E")

    static let precipitationDropBlue = Color(hex: "61ADFA")

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
