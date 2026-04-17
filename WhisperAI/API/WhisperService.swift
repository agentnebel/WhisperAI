import Foundation

class WhisperService {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func transcribe(audioURL: URL) async throws -> String {
        let boundary = UUID().uuidString

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        var body = Data()

        // model
        body.appendFormField(named: "model", value: "whisper-1", boundary: boundary)

        // audio file
        let audioData = try Data(contentsOf: audioURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperError.networkError
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unbekannter Fehler"
            throw WhisperError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        let result = try JSONDecoder().decode(WhisperResponse.self, from: data)
        return result.text
    }
}

private struct WhisperResponse: Decodable {
    let text: String
}

enum WhisperError: LocalizedError {
    case networkError
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Netzwerkfehler bei der Transkription."
        case .apiError(let code, let message):
            return "Whisper API Fehler (\(code)): \(message)"
        }
    }
}

private extension Data {
    mutating func appendFormField(named name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }
}
