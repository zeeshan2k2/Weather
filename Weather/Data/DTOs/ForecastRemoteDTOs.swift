import Foundation

struct PlaceSearchResponseDTO: Decodable {
    let results: [RemotePlaceDTO]?
}

struct RemotePlaceDTO: Decodable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?
    let timezone: String
}

extension WeatherPlace {
    init(dto: RemotePlaceDTO) {
        id = dto.id
        name = dto.name
        latitude = dto.latitude
        longitude = dto.longitude
        country = dto.country
        admin1 = dto.admin1
        timezone = dto.timezone
    }
}

struct ForecastResponseDTO: Decodable {
    let current: CurrentConditionsDTO
    let daily: DailySeriesDTO
    let hourly: HourlySeriesDTO

    func toWeatherForecast(timeZoneIdentifier: String) throws -> WeatherForecast {
        let dailyItems = try daily.toDailyItems(timeZoneIdentifier: timeZoneIdentifier)
        let hourlyItems = try hourly.toHourlyItems()
        return WeatherForecast(
            currentTempF: Int(current.temperature2m.rounded()),
            currentCode: current.weatherCode,
            currentIsDay: current.isDay == 1,
            apparentTempF: current.apparentTemperature.map { Int($0.rounded()) },
            relativeHumidityPercent: current.relativeHumidity2m,
            precipitationMm: current.precipitation,
            windSpeedMph: current.windSpeed10m,
            daily: dailyItems,
            hourly: hourlyItems
        )
    }
}

struct CurrentConditionsDTO: Decodable {
    let temperature2m: Double
    let apparentTemperature: Double?
    let relativeHumidity2m: Int?
    let weatherCode: Int
    let isDay: Int
    let precipitation: Double?
    let windSpeed10m: Double?

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case relativeHumidity2m = "relative_humidity_2m"
        case weatherCode = "weather_code"
        case isDay = "is_day"
        case precipitation
        case windSpeed10m = "wind_speed_10m"
    }
}

struct DailySeriesDTO: Decodable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationProbabilityMax: [Int]?
    let sunrise: [String]
    let sunset: [String]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case sunrise
        case sunset
    }

    func toDailyItems(timeZoneIdentifier: String) throws -> [DailyForecastItem] {
        let n = time.count
        guard n == weatherCode.count,
              n == temperature2mMax.count,
              n == temperature2mMin.count,
              n == sunrise.count,
              n == sunset.count,
              n > 0 else {
            throw URLError(.cannotParseResponse)
        }
        let precip = precipitationProbabilityMax
        if let precip, precip.count != n {
            throw URLError(.cannotParseResponse)
        }
        return (0 ..< n).map { i in
            DailyForecastItem(
                id: time[i],
                weekdayAbbrev: Self.weekdayAbbrev(from: time[i], timeZoneIdentifier: timeZoneIdentifier),
                weatherCode: weatherCode[i],
                highTempF: Int(temperature2mMax[i].rounded()),
                lowTempF: Int(temperature2mMin[i].rounded()),
                precipitationProbabilityMax: precip?[i],
                sunrise: sunrise[i],
                sunset: sunset[i]
            )
        }
    }

    private static func weekdayAbbrev(from dateString: String, timeZoneIdentifier: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dateString) else { return "---" }
        parser.dateFormat = "EEE"
        return parser.string(from: date).uppercased()
    }
}

struct HourlySeriesDTO: Decodable {
    let time: [String]
    let temperature2m: [Double]
    let weatherCode: [Int]
    let precipitationProbability: [Int]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case precipitationProbability = "precipitation_probability"
    }

    func toHourlyItems() throws -> [HourlyForecastItem] {
        let n = time.count
        guard n == temperature2m.count, n == weatherCode.count, n > 0 else {
            throw URLError(.cannotParseResponse)
        }
        let precip = precipitationProbability
        if let precip, precip.count != n {
            throw URLError(.cannotParseResponse)
        }
        return (0 ..< n).map { i in
            HourlyForecastItem(
                timeISO: time[i],
                tempF: Int(temperature2m[i].rounded()),
                weatherCode: weatherCode[i],
                precipitationProbabilityPercent: precip?[i]
            )
        }
    }
}
