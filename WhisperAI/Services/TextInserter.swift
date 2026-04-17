import AppKit
import Carbon.HIToolbox

class TextInserter {

    static func insert(text: String) {
        let pasteboard = NSPasteboard.general

        // Snapshot previous clipboard (string only — restoring arbitrary types is unreliable)
        let previousClipboard = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        // Nach unserem setString ist changeCount inkrementiert — diesen Wert merken,
        // um später zu erkennen ob der Nutzer zwischenzeitlich selbst etwas kopiert hat.
        let ourChangeCount = pasteboard.changeCount
        NSLog("WhisperAI: Text in Zwischenablage kopiert (%d Zeichen)", text.count)

        guard AXIsProcessTrusted() else {
            NSLog("WhisperAI: Keine Accessibility-Berechtigung")
            // Non-blocking: open System Preferences directly, no modal alert
            DispatchQueue.main.async { openAccessibilitySettings() }
            return
        }

        // Give focus time to return to the previous app before we paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            simulatePaste()

            // Restore previous clipboard content after paste completes.
            //
            // Das Delay skaliert mit der Textlänge: kurze Texte sind sofort gelesen,
            // lange Texte brauchen auf stark ausgelasteten Macs oder in Apps mit
            // asynchronem Paste-Handling (Electron, Office) länger. Bei 2s gedeckelt,
            // damit der Nutzer nicht ewig auf sein altes Clipboard warten muss.
            let restoreDelay = max(0.6, min(2.0, 0.6 + Double(text.count) / 20_000))

            DispatchQueue.main.asyncAfter(deadline: .now() + restoreDelay) {
                // Wenn der changeCount seit unserem Set nicht mehr unser Wert ist,
                // hat jemand anderes (Nutzer, andere App) ins Clipboard geschrieben.
                // Dann dessen Inhalt nicht überschreiben.
                guard pasteboard.changeCount == ourChangeCount else {
                    NSLog("WhisperAI: Clipboard inzwischen geändert — kein Restore")
                    return
                }
                pasteboard.clearContents()
                if let prev = previousClipboard {
                    pasteboard.setString(prev, forType: .string)
                }
            }
        }
    }

    private static func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
              let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
            NSLog("WhisperAI: Konnte Paste-Event nicht erstellen")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags   = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
        NSLog("WhisperAI: ⌘V simuliert")
    }

    // MARK: - Permission Handling

    static func checkAndRequest() -> Bool {
        let trusted = AXIsProcessTrusted()
        NSLog("WhisperAI: AXIsProcessTrusted = %@", trusted ? "JA" : "NEIN")

        if trusted {
            // Already trusted — clear prompt flag so a future revoke triggers a new system prompt.
            // Onboarding wird bei fehlender Permission bewusst bei jedem Start erneut gezeigt.
            UserDefaults.standard.removeObject(forKey: "accessibilityPromptShown")
            return true
        }

        // Only show the system prompt once; afterwards handle silently
        let alreadyPrompted = UserDefaults.standard.bool(forKey: "accessibilityPromptShown")
        if !alreadyPrompted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            UserDefaults.standard.set(true, forKey: "accessibilityPromptShown")
        }

        return false
    }

    private static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
