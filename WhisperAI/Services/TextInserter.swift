import AppKit
import Carbon.HIToolbox

class TextInserter {

    static func insert(text: String) {
        let pasteboard = NSPasteboard.general

        // Snapshot previous clipboard (string only — restoring arbitrary types is unreliable)
        let previousClipboard = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
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
            // Only restore if our inserted text is still there (user may have copied something new).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                guard pasteboard.string(forType: .string) == text else { return }
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
