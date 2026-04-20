import Foundation

enum ForecastInsightOllamaService {

    private static let systemPrompt = """
    You write concise weather insight copy for a mobile weather app. Use ONLY the facts given in the user message. \
    Produce 2–4 short paragraphs in plain English. Do not invent temperatures, locations, or precipitation chances. \
    If facts conflict, prefer the headline numbers over older text. Stay friendly and practical. \
    Never use two ASCII hyphens in a row (--) or markdown dash rules; use commas, periods, or the word and instead.
    """

    static func fetchNarrative(payload: ForecastInsightPayload) async -> String? {
        let user = userPrompt(from: payload)
        do {
            let text = try await OllamaChatClient.chat(
                endpoint: OllamaInsightConfiguration.chatEndpointURL,
                model: OllamaInsightConfiguration.modelName,
                systemPrompt: systemPrompt,
                userPrompt: user
            )
            return text
        } catch {
            return nil
        }
    }

    private static func userPrompt(from payload: ForecastInsightPayload) -> String {
        var lines: [String] = []
        lines.append("City / label: \(payload.cityLine)")
        lines.append("Condition (headline): \(payload.headlineCondition)")
        lines.append("Temperature (headline): \(payload.headlineTemp)°\(payload.headlineUnit)")
        lines.append("Wear (fact): \(payload.wearLine)")
        if let carry = payload.carryLine {
            lines.append("Carry item (fact): \(carry)")
        }
        lines.append("")
        lines.append("Baseline narrative built from the same forecast (rewrite or tighten; do not contradict headline facts):")
        lines.append(payload.summaryParagraph)
        return lines.joined(separator: "\n")
    }
}
