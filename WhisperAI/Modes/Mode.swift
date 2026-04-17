import Foundation

struct Mode: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var prompt: String

    init(id: UUID = UUID(), name: String, prompt: String) {
        self.id = id
        self.name = name
        self.prompt = prompt
    }

    static func == (lhs: Mode, rhs: Mode) -> Bool {
        lhs.id == rhs.id
    }
}
