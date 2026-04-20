import Foundation

enum OllamaInsightConfiguration {
    private static let baseURLKey = "ollama.baseURL"
    private static let modelKey = "ollama.model"

    static var chatEndpointURL: URL {
        let raw = UserDefaults.standard.string(forKey: baseURLKey) ?? defaultBaseURLString
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(trimmed)/api/chat")
            ?? URL(string: "\(defaultBaseURLString)/api/chat")!
    }

    static var modelName: String {
        UserDefaults.standard.string(forKey: modelKey) ?? "llama3.2"
    }

    static let defaultBaseURLString = "http://127.0.0.1:11434"
}
