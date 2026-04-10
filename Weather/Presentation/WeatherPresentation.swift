
import Foundation

enum WeatherPresentation {

    /// Typical connectivity / reachability failures (for offline-style UI).
    static func isLikelyConnectivityFailure(_ error: Error) -> Bool {
        APIManager.isLikelyConnectivityFailure(error)
    }

    /// Maps WMO weather codes (Open-Meteo) to SF Symbols.
    static func symbolName(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0:
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2:
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55:
            return "cloud.drizzle.fill"
        case 61, 63, 65:
            return "cloud.rain.fill"
        case 66, 67:
            return "cloud.sleet.fill"
        case 71, 73, 75, 77:
            return "cloud.snow.fill"
        case 80, 81, 82:
            return "cloud.heavyrain.fill"
        case 85, 86:
            return "cloud.snow.fill"
        case 95:
            return "cloud.bolt.fill"
        case 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }

    /// Short condition label for UI (WMO codes used by Open-Meteo).
    static func conditionDescription(for code: Int, isDay: Bool) -> String {
        switch code {
        case 0:
            return isDay ? "Sunny" : "Clear"
        case 1:
            return "Mostly clear"
        case 2:
            return "Partly cloudy"
        case 3:
            return "Overcast"
        case 45, 48:
            return "Fog"
        case 51, 53, 55:
            return "Drizzle"
        case 61:
            return "Light rain"
        case 63:
            return "Rain"
        case 65:
            return "Heavy rain"
        case 66, 67:
            return "Freezing rain"
        case 71, 73, 75:
            return "Snow"
        case 77:
            return "Snow grains"
        case 80, 81, 82:
            return "Rain showers"
        case 85, 86:
            return "Snow showers"
        case 95:
            return "Thunderstorm"
        case 96, 99:
            return "Thunderstorm & hail"
        default:
            return "Weather"
        }
    }
}
