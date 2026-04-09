
import SwiftUI

struct WeatherDay: Identifiable, Hashable {
    let id: String
    var dayOfWeek: String
    var imageName: String
    var weatherCode: Int
    /// Daily high (°F); UI still uses this as the main number on the strip.
    var temperature: Int
    var lowTempF: Int?
    var precipitationProbabilityMax: Int?
    var sunrise: String?
    var sunset: String?
}
