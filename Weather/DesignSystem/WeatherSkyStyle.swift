
import SwiftUI

enum WeatherSkyStyle {

    private enum Kind {
        case clear, partlyCloudy, cloudy, fog, rain, heavyRain, snow, thunder
    }

    private enum TempBucket {
        case cool, mild, warm
    }

    /// Top → bottom colors for a full-screen vertical gradient.
    static func gradientColors(weatherCode: Int, isDay: Bool, tempFahrenheit: Int) -> [Color] {
        let kind = skyKind(from: weatherCode)
        let bucket = tempBucket(tempFahrenheit)
        return palette(kind: kind, isDay: isDay, bucket: bucket)
    }

    private static func skyKind(from code: Int) -> Kind {
        switch code {
        case 0: return .clear
        case 1, 2: return .partlyCloudy
        case 3: return .cloudy
        case 45, 48: return .fog
        case 51 ... 57: return .rain
        case 61 ... 65: return .rain
        case 66, 67: return .heavyRain
        case 71 ... 77: return .snow
        case 80 ... 82: return .heavyRain
        case 85, 86: return .snow
        case 95 ... 99: return .thunder
        default: return .cloudy
        }
    }

    private static func tempBucket(_ f: Int) -> TempBucket {
        if f < 42 { return .cool }
        if f < 78 { return .mild }
        return .warm
    }

    private static func palette(kind: Kind, isDay: Bool, bucket: TempBucket) -> [Color] {
        switch kind {
        case .clear:
            if isDay {
                switch bucket {
                case .cool: return [Color(hex: "8AD0FF"), Color(hex: "3578D0")]
                case .mild: return [Color(hex: "5CB0FF"), Color(hex: "2563C8")]
                case .warm: return [Color(hex: "6BC8FF"), Color(hex: "E07A4F")]
                }
            }
            return [Color(hex: "2A4A78"), Color(hex: "0B1428")]

        case .partlyCloudy:
            if isDay {
                switch bucket {
                case .cool: return [Color(hex: "9BC4EB"), Color(hex: "5A7AA0")]
                case .mild: return [Color(hex: "8BB8EA"), Color(hex: "4A6FA0")]
                case .warm: return [Color(hex: "A8D4FF"), Color(hex: "C4805A")]
                }
            }
            return [Color(hex: "354A60"), Color(hex: "1A2533")]

        case .cloudy:
            if isDay {
                return [Color(hex: "9CAAB8"), Color(hex: "6B7785")]
            }
            return [Color(hex: "3D4754"), Color(hex: "252B32")]

        case .fog:
            if isDay {
                return [Color(hex: "B8C5CE"), Color(hex: "8A969E")]
            }
            return [Color(hex: "5A6470"), Color(hex: "3E464E")]

        case .rain:
            if isDay {
                return [Color(hex: "6B8CA8"), Color(hex: "4A6578")]
            }
            return [Color(hex: "3D4F5F"), Color(hex: "2A3844")]

        case .heavyRain:
            if isDay {
                return [Color(hex: "4A5F72"), Color(hex: "354550")]
            }
            return [Color(hex: "2A3540"), Color(hex: "1A2228")]

        case .snow:
            if isDay {
                return [Color(hex: "D4E6F2"), Color(hex: "9BB8D0")]
            }
            return [Color(hex: "5A6B7A"), Color(hex: "3D4A56")]

        case .thunder:
            if isDay {
                return [Color(hex: "6B5B95"), Color(hex: "3D2F55")]
            }
            return [Color(hex: "3A2F50"), Color(hex: "120A1C")]
        }
    }
}
