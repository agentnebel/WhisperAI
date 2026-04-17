import Foundation

class LLMService {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model: String

    init(apiKey: String, model: String = "gpt-4o-mini") {
        self.apiKey = apiKey
        self.model = model
    }

    func process(transcript: String, systemPrompt: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // {language}-Platzhalter durch die in den Einstellungen gewählte Sprache ersetzen.
        // Ermöglicht dynamische Übersetzungsmodi ohne hart kodierte Sprache im Prompt.
        let resolvedPrompt = systemPrompt.replacingOccurrences(
            of: "{language}",
            with: SettingsManager.shared.translationLanguage
        )

        // Das Transkript wird in <transcript>-Tags eingebettet, damit das Modell
        // Nutzerdaten klar vom System-Prompt trennt und Inhalte nicht als
        // Anweisungen interpretiert (verhindert, dass Fragen beantwortet werden).
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": resolvedPrompt],
                ["role": "user", "content": "<transcript>\n\(transcript)\n</transcript>"]
            ],
            "temperature": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unbekannter Fehler"
            throw LLMError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let result = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw LLMError.emptyResponse
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

enum LLMError: LocalizedError {
    case networkError
    case apiError(statusCode: Int, message: String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Netzwerkfehler bei der Textverarbeitung."
        case .apiError(let code, let message):
            return "LLM API Fehler (\(code)): \(message)"
        case .emptyResponse:
            return "Leere Antwort vom LLM erhalten."
        }
    }
}
