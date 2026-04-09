
import SwiftUI

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
