import Foundation

enum WeatherDateFormatting {
    private static let posix = Locale(identifier: "en_US_POSIX")

    private static let dayIdInput = makeFormatter("yyyy-MM-dd")
    private static let longDateOutput = makeFormatter("EEEE, MMMM d")
    private static let hourlyISOInput = makeFormatter("yyyy-MM-dd'T'HH:mm")
    private static let hour12h = makeFormatter("h a")
    private static let sunEvent12h = makeFormatter("h:mm a")

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = posix
        f.dateFormat = format
        return f
    }

    private static func timeZone(for identifier: String) -> TimeZone {
        TimeZone(identifier: identifier) ?? .gmt
    }

    static func longDateLabel(dayId: String, timeZoneIdentifier: String) -> String {
        let tz = timeZone(for: timeZoneIdentifier)
        dayIdInput.timeZone = tz
        longDateOutput.timeZone = tz
        guard let date = dayIdInput.date(from: dayId) else { return "" }
        return longDateOutput.string(from: date)
    }

    static func calendarDayId(for date: Date, timeZoneIdentifier: String) -> String {
        let tz = timeZone(for: timeZoneIdentifier)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)
        let d = calendar.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func date(fromHourlyISO timeISO: String, timeZoneIdentifier: String) -> Date? {
        let tz = timeZone(for: timeZoneIdentifier)
        hourlyISOInput.timeZone = tz
        return hourlyISOInput.date(from: timeISO)
    }

    static func formattedHourLabel(timeISO: String, timeZoneIdentifier: String, referenceNow: Date = Date()) -> String {
        let tz = timeZone(for: timeZoneIdentifier)
        hourlyISOInput.timeZone = tz
        hour12h.timeZone = tz
        guard let date = hourlyISOInput.date(from: timeISO) else { return "--" }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        if calendar.isDate(date, equalTo: referenceNow, toGranularity: .hour) {
            return "Now"
        }
        return hour12h.string(from: date)
    }

    static func hourlyIsDaylight(timeISO: String, timeZoneIdentifier: String, fallbackIsDay: Bool) -> Bool {
        let tz = timeZone(for: timeZoneIdentifier)
        hourlyISOInput.timeZone = tz
        guard let date = hourlyISOInput.date(from: timeISO) else { return fallbackIsDay }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let hour = calendar.component(.hour, from: date)
        return hour >= 7 && hour < 19
    }

    static func formattedSunEvent(iso: String?, timeZoneIdentifier: String) -> String {
        guard let iso else { return "—" }
        let tz = timeZone(for: timeZoneIdentifier)
        hourlyISOInput.timeZone = tz
        sunEvent12h.timeZone = tz
        guard let date = hourlyISOInput.date(from: iso) else { return "—" }
        return sunEvent12h.string(from: date)
    }
}
