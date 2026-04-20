import Foundation

enum ForecastInsightCopyBuilder {

    static func build(
        model: WeatherDashboardModel,
        cityName: String,
        useCelsius: Bool,
        unitSuffix: String,
        timeZoneIdentifier: String
    ) -> ForecastInsightPayload {
        guard !model.weatherData.isEmpty else {
            let t = DashboardTemperature.display(fahrenheit: model.currentTemp, useCelsius: useCelsius)
            let condition = WeatherPresentation.conditionDescription(
                for: model.currentWeatherCode,
                isDay: model.currentIsDay
            )
            return ForecastInsightPayload(
                cityLine: cityName,
                headlineCondition: condition,
                headlineTemp: "\(t)",
                headlineUnit: unitSuffix,
                summaryParagraph: "Hang tight. We’re still assembling today’s hourly strip. Pull to refresh or wait a beat, then open this card again.",
                wearLine: wearAdvice(tempFahrenheit: model.currentTemp),
                carryLine: nil
            )
        }

        let condition = WeatherPresentation.conditionDescription(
            for: model.currentWeatherCode,
            isDay: model.currentIsDay
        )
        let tempDisplay = DashboardTemperature.display(fahrenheit: model.currentTemp, useCelsius: useCelsius)
        let today = model.weatherData.first

        let highDisplay = today.map { DashboardTemperature.display(fahrenheit: $0.temperature, useCelsius: useCelsius) }
        let lowDisplay = today?.lowTempF.map { DashboardTemperature.display(fahrenheit: $0, useCelsius: useCelsius) }

        let slice12 = model.hourlyForecastSliceFromNow(timeZoneIdentifier: timeZoneIdentifier, limit: 12)
        let maxPop12 = slice12.compactMap(\.precipitationProbabilityPercent).max() ?? 0
        let dailyPop = today?.precipitationProbabilityMax ?? 0

        let summary = paragraph(
            condition: condition,
            tempDisplay: tempDisplay,
            unit: unitSuffix,
            high: highDisplay,
            low: lowDisplay,
            apparentDelta: apparentDeltaSentence(
                apparentF: model.apparentTempF,
                currentF: model.currentTemp,
                useCelsius: useCelsius,
                unit: unitSuffix
            ),
            windMph: model.windSpeedMph,
            maxPop12: maxPop12,
            dailyPopMax: dailyPop
        )

        let wear = wearAdvice(tempFahrenheit: model.currentTemp)
        let carry = carryAdvice(maxPopNext12: maxPop12, dailyPopMax: dailyPop)

        return ForecastInsightPayload(
            cityLine: cityName,
            headlineCondition: condition,
            headlineTemp: "\(tempDisplay)",
            headlineUnit: unitSuffix,
            summaryParagraph: summary,
            wearLine: wear,
            carryLine: carry
        )
    }

    private static func apparentDeltaSentence(
        apparentF: Int?,
        currentF: Int,
        useCelsius: Bool,
        unit: String
    ) -> String? {
        guard let apparentF else { return nil }
        let apparentD = DashboardTemperature.display(fahrenheit: apparentF, useCelsius: useCelsius)
        let currentD = DashboardTemperature.display(fahrenheit: currentF, useCelsius: useCelsius)
        let delta = abs(apparentD - currentD)
        guard delta >= 4 else { return nil }
        if apparentD > currentD {
            return "It feels noticeably warmer than the measured \(currentD)°\(unit), closer to \(apparentD)°\(unit) with humidity and breeze."
        }
        return "It feels cooler than \(currentD)°\(unit); wind or evaporation can make it feel closer to \(apparentD)°\(unit)."
    }

    private static func paragraph(
        condition: String,
        tempDisplay: Int,
        unit: String,
        high: Int?,
        low: Int?,
        apparentDelta: String?,
        windMph: Double?,
        maxPop12: Int,
        dailyPopMax: Int
    ) -> String {
        var lines: [String] = []
        lines.append(
            "Right now it’s \(condition.lowercased()) around \(tempDisplay)°\(unit)."
        )

        if let apparentDelta {
            lines.append(apparentDelta)
        }

        if let high, let low {
            lines.append("Today looks like roughly \(high)°\(unit) at the warmest and \(low)°\(unit) at the coolest.")
        }

        if maxPop12 >= 45 || dailyPopMax >= 45 {
            lines.append(
                "Rain chances peak around \(max(maxPop12, dailyPopMax))% in what we’re showing next. Showers may show up later even if it’s dry at this hour."
            )
        } else {
            lines.append(
                "Precipitation chances stay modest over the next several hours unless the forecast refreshes upward."
            )
        }

        if let windMph, windMph >= 18 {
            lines.append(
                String(format: "Wind’s fairly brisk near %.0f mph, so add a secure layer so nothing flaps loose.", windMph)
            )
        } else if let windMph, windMph >= 12 {
            lines.append(
                String(format: "A breezy %.0f mph keeps things comfortable but can add a nip, so a light jacket helps at the gusts.", windMph)
            )
        }

        return lines.joined(separator: "\n\n")
    }

    private static func wearAdvice(tempFahrenheit: Int) -> String {
        switch tempFahrenheit {
        case ..<38:
            return "Bundle up: insulating layers, gloves, and a hat if you’ll be outside more than a few minutes."
        case 38 ..< 50:
            return "Wear a warm jacket or coat; lighter layers underneath so you can adapt indoors."
        case 50 ..< 65:
            return "Light sweater or fleece over a tee; mornings and evenings cool off fast."
        case 65 ..< 75:
            return "Comfortable street clothes; keep a hoodie nearby for drafts or sunset."
        case 75 ..< 85:
            return "Breathable fabrics and sun coverage if you’ll be outdoors, and hydrate on longer walks."
        default:
            return "Loose, light clothing and shade breaks; hydration matters more than extra layers."
        }
    }

    private static func carryAdvice(maxPopNext12: Int, dailyPopMax: Int) -> String? {
        let peak = max(maxPopNext12, dailyPopMax)
        if peak >= 55 {
            return "Bring a compact umbrella or rain shell; odds favor getting wet at some point today."
        }
        if peak >= 35 {
            return "Slip a packable umbrella in your bag; showers could appear even if skies look fine now."
        }
        return nil
    }
}
