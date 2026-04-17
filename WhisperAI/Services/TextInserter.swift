import AppKit
import Carbon.HIToolbox

class TextInserter {

    static func insert(text: String) {
        let pasteboard = NSPasteboard.general

        // Snapshot previous clipboard (string only — restoring arbitrary types is unreliable)
        let previousClipboard = pasteboard.string(forType: .string)

        let snapshotCount = pasteboard.changeCount

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        NSLog("WhisperAI: Text in Zwischenablage kopiert (%d Zeichen)", text.count)

        // Nach unserem Set: changeCount ist jetzt snapshotCount + 1
        let ourCount = pasteboard.changeCount

        guard AXIsProcessTrusted() else {
            NSLog("WhisperAI: Keine Accessibility-Berechtigung")
            // Non-blocking: open System Preferences directly, no modal alert
            DispatchQueue.main.async { openAccessibilitySettings() }
            return
        }

        // Give focus time to return to the previous app before we paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            simulatePaste()

            // Dynamisches Restore-Delay: skaliert mit Textlänge
            let restoreDelay = max(0.6, min(2.0, 0.6 + Double(text.count) / 20_000))

            // Restore previous clipboard content after paste completes.
            // Nur restoren wenn Clipboard noch unser Text ist UND Nutzer
            // in der Zwischenzeit nichts Neues kopiert hat.
            DispatchQueue.main.asyncAfter(deadline: .now() + restoreDelay) {
                guard pasteboard.changeCount == ourCount else { return }
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
