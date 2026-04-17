import Foundation

class ModeManager {
    static let shared = ModeManager()

    private(set) var modes: [Mode]
    var activeMode: Mode

    private let storageURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("WhisperAI", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        } catch {
            NSLog("WhisperAI: App-Support-Verzeichnis konnte nicht angelegt werden: %@", error.localizedDescription)
        }
        storageURL = appDir.appendingPathComponent("modes.json")

        if FileManager.default.fileExists(atPath: storageURL.path) {
            do {
                let data = try Data(contentsOf: storageURL)
                let saved = try JSONDecoder().decode([Mode].self, from: data)
                if !saved.isEmpty {
                    modes = saved
                } else {
                    NSLog("WhisperAI: Gespeicherte Modi-Liste leer — Defaults werden verwendet")
                    modes = Self.defaultModes
                }
            } catch {
                NSLog("WhisperAI: Modi konnten nicht geladen werden (%@) — Defaults werden verwendet", error.localizedDescription)
                modes = Self.defaultModes
            }
        } else {
            modes = Self.defaultModes
        }

        if let savedActiveId = UserDefaults.standard.string(forKey: "activeModeId"),
           let uuid = UUID(uuidString: savedActiveId),
           let match = modes.first(where: { $0.id == uuid }) {
            activeMode = match
        } else {
            activeMode = modes[0]
        }
    }

    func setActiveMode(_ mode: Mode) {
        activeMode = mode
        UserDefaults.standard.set(mode.id.uuidString, forKey: "activeModeId")
    }

    func addMode(_ mode: Mode) {
        modes.append(mode)
        save()
    }

    func updateMode(_ mode: Mode) {
        if let index = modes.firstIndex(where: { $0.id == mode.id }) {
            modes[index] = mode
            if activeMode.id == mode.id {
                activeMode = mode
            }
            save()
        }
    }

    func removeMode(_ mode: Mode) {
        guard modes.count > 1 else { return }
        modes.removeAll { $0.id == mode.id }
        if activeMode.id == mode.id {
            activeMode = modes[0]
        }
        save()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(modes)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            NSLog("WhisperAI: Modi konnten nicht gespeichert werden: %@", error.localizedDescription)
        }
    }

    static let defaultModes: [Mode] = [
        Mode(
            name: "Standard",
            prompt: """
            Du bist ein professioneller Assistent für Textaufbereitung.
            Du erhältst ein Transkript einer Sprachaufnahme, in der eine Person informell oder spontan spricht.
            Formuliere den Text so um, dass er sich wie eine geschriebene Nachricht liest.
            Ändere nichts am Inhalt.
            Verbessere Grammatik, Struktur und Lesbarkeit.
            Der Text soll natürlich wirken, wie von einem Menschen geschrieben.
            Antworte ausschließlich mit dem verbesserten Text, ohne Erklärungen oder Kommentare.
            """
        ),
        Mode(
            name: "Freundlich",
            prompt: """
            Du bist ein professioneller Assistent für Textaufbereitung.
            Der folgende Text wurde emotional eingesprochen.
            Wandle ihn in eine sachliche, freundliche und professionelle Nachricht um.
            Entferne aggressive Formulierungen, Übertreibungen und Schimpfwörter.
            Behalte den Inhalt bei.
            Der Ton soll warm und respektvoll sein.
            Antworte ausschließlich mit dem verbesserten Text, ohne Erklärungen oder Kommentare.
            """
        )
    ]
}
