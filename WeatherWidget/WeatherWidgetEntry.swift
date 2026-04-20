import WidgetKit

struct WidgetHourlySlot: Sendable {
    let hourLabel: String
    let tempF: Int
    let symbolName: String

    var stripIdentifier: String { "\(hourLabel)|\(tempF)|\(symbolName)" }
}

struct WeatherWidgetEntry: TimelineEntry {
    let date: Date
    let cityName: String
    let useCelsius: Bool
    let temperatureF: Int
    let dailyHighTempF: Int?
    let dailyLowTempF: Int?
    let hourlySlots: [WidgetHourlySlot]
    let latitude: Double?
    let longitude: Double?
    let conditionText: String
    let symbolName: String
    let weatherCode: Int
    let isDay: Bool
    let isPlaceholder: Bool
    let errorMessage: String?
}

extension WeatherWidgetEntry {
    var highLowPair: (high: Int, low: Int)? {
        guard let h = dailyHighTempF, let l = dailyLowTempF else { return nil }
        return (h, l)
    }

    var unitSuffix: String { useCelsius ? "C" : "F" }

    func tempDisplay(_ fahrenheit: Int) -> Int {
        TemperatureUnitDisplay.displayValue(fahrenheit: fahrenheit, useCelsius: useCelsius)
    }

    static func placeholder() -> WeatherWidgetEntry {
        WeatherWidgetEntry(
            date: Date(),
            cityName: "Cupertino, CA",
            useCelsius: false,
            temperatureF: 72,
            dailyHighTempF: 78,
            dailyLowTempF: 62,
            hourlySlots: [
                WidgetHourlySlot(hourLabel: "2 PM", tempF: 74, symbolName: "sun.max.fill"),
                WidgetHourlySlot(hourLabel: "3 PM", tempF: 75, symbolName: "sun.max.fill"),
                WidgetHourlySlot(hourLabel: "4 PM", tempF: 73, symbolName: "cloud.sun.fill"),
                WidgetHourlySlot(hourLabel: "5 PM", tempF: 72, symbolName: "cloud.fill"),
                WidgetHourlySlot(hourLabel: "6 PM", tempF: 71, symbolName: "cloud.fill"),
            ],
            latitude: 37.3230,
            longitude: -122.0322,
            conditionText: "Sunny",
            symbolName: "sun.max.fill",
            weatherCode: 0,
            isDay: true,
            isPlaceholder: true,
            errorMessage: nil
        )
    }

    static func invalidLocation(cityName: String, useCelsius: Bool) -> WeatherWidgetEntry {
        WeatherWidgetEntry(
            date: Date(),
            cityName: cityName,
            useCelsius: useCelsius,
            temperatureF: 0,
            dailyHighTempF: nil,
            dailyLowTempF: nil,
            hourlySlots: [],
            latitude: nil,
            longitude: nil,
            conditionText: "",
            symbolName: "exclamationmark.triangle.fill",
            weatherCode: 3,
            isDay: false,
            isPlaceholder: false,
            errorMessage: "Invalid location"
        )
    }

    static func success(
        cityName: String,
        useCelsius: Bool,
        temperatureF: Int,
        dailyHighTempF: Int?,
        dailyLowTempF: Int?,
        hourlySlots: [WidgetHourlySlot],
        latitude: Double,
        longitude: Double,
        conditionText: String,
        symbolName: String,
        weatherCode: Int,
        isDay: Bool
    ) -> WeatherWidgetEntry {
        WeatherWidgetEntry(
            date: Date(),
            cityName: cityName,
            useCelsius: useCelsius,
            temperatureF: temperatureF,
            dailyHighTempF: dailyHighTempF,
            dailyLowTempF: dailyLowTempF,
            hourlySlots: hourlySlots,
            latitude: latitude,
            longitude: longitude,
            conditionText: conditionText,
            symbolName: symbolName,
            weatherCode: weatherCode,
            isDay: isDay,
            isPlaceholder: false,
            errorMessage: nil
        )
    }

    static func failure(
        cityName: String,
        useCelsius: Bool,
        latitude: Double?,
        longitude: Double?,
        message: String
    ) -> WeatherWidgetEntry {
        WeatherWidgetEntry(
            date: Date(),
            cityName: cityName,
            useCelsius: useCelsius,
            temperatureF: 0,
            dailyHighTempF: nil,
            dailyLowTempF: nil,
            hourlySlots: [],
            latitude: latitude,
            longitude: longitude,
            conditionText: "",
            symbolName: "wifi.slash",
            weatherCode: 3,
            isDay: false,
            isPlaceholder: false,
            errorMessage: message
        )
    }
}
