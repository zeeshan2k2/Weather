import Foundation

struct WeatherDay: Identifiable, Hashable, Sendable {
    let id: String
    var dayOfWeek: String
    var imageName: String
    var weatherCode: Int

    var temperature: Int
    var lowTempF: Int?
    var precipitationProbabilityMax: Int?
    var sunrise: String?
    var sunset: String?
}
