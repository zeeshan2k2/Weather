import Foundation

enum OllamaChatClientError: LocalizedError {
    case badStatus(Int, String?)
    case emptyAssistantReply

    var errorDescription: String? {
        switch self {
        case let .badStatus(code, body):
            return "Ollama HTTP \(code): \(body ?? "")"
        case .emptyAssistantReply:
            return "Ollama returned an empty reply."
        }
    }
}

struct OllamaChatRequestDTO: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let stream: Bool
}

struct OllamaChatResponseDTO: Decodable {
    struct Message: Decodable {
        let role: String
        let content: String
    }

    let message: Message?
}

struct OllamaErrorEnvelopeDTO: Decodable {
    let error: String?
}

enum OllamaChatClient {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    static func chat(
        endpoint: URL,
        model: String,
        systemPrompt: String,
        userPrompt: String
    ) async throws -> String {
        let body = OllamaChatRequestDTO(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt),
            ],
            stream: false
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw OllamaChatClientError.badStatus(-1, nil)
        }

        guard (200 ..< 300).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8)
            throw OllamaChatClientError.badStatus(http.statusCode, snippet)
        }

        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(OllamaErrorEnvelopeDTO.self, from: data), let err = envelope.error, !err.isEmpty {
            throw OllamaChatClientError.badStatus(http.statusCode, err)
        }

        let decoded = try decoder.decode(OllamaChatResponseDTO.self, from: data)
        guard let text = decoded.message?.content.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw OllamaChatClientError.emptyAssistantReply
        }

        return text
    }
}
