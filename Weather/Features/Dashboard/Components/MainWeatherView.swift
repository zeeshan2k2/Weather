import SwiftUI

struct MainWeatherView: View {

    var imageName: String
    var temperature: Int
    var unit: String = "F"
    var conditionText: String = ""

    var feelsLike: Int? = nil

    var body: some View {
        VStack(spacing: 0) {
            WeatherSkyConditionSymbol.resizableImage(systemName: imageName)
                .frame(width: 160, height: 160)
                .frame(height: 160, alignment: .top)
                .clipped()

            VStack(spacing: 6) {
                Text("\(temperature)°\(unit)")
                    .font(.system(size: 68, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                    .lineLimit(1)
                    .padding(.bottom, -12)

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
