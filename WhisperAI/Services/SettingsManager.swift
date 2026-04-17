import AppKit
import Carbon.HIToolbox

class SettingsManager {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard
    private static let apiKeyAccount = "openai_api_key"
    private var apiKeyMigrated = false

    // MARK: - API Key (Keychain-backed)

    var apiKey: String {
        get {
            migrateApiKeyIfNeeded()
            return KeychainHelper.get(Self.apiKeyAccount) ?? ""
        }
        set {
            migrateApiKeyIfNeeded()
            if newValue.isEmpty {
                KeychainHelper.delete(Self.apiKeyAccount)
            } else {
                KeychainHelper.set(newValue, for: Self.apiKeyAccount)
            }
        }
    }

    /// Verschiebt einen eventuell in UserDefaults abgelegten API-Key (Legacy)
    /// einmalig in die Keychain und räumt UserDefaults auf.
    private func migrateApiKeyIfNeeded() {
        guard !apiKeyMigrated else { return }
        apiKeyMigrated = true

        guard let legacy = defaults.string(forKey: Self.apiKeyAccount),
              !legacy.isEmpty else { return }

        if KeychainHelper.get(Self.apiKeyAccount) == nil {
            if KeychainHelper.set(legacy, for: Self.apiKeyAccount) {
                NSLog("WhisperAI: API Key von UserDefaults nach Keychain migriert")
            }
        }
        defaults.removeObject(forKey: Self.apiKeyAccount)
    }

    var maskedApiKey: String {
        let key = apiKey
        guard key.count > 4 else { return String(repeating: "•", count: max(key.count, 8)) }
        let prefix = String(key.prefix(4))
        let asterisks = String(repeating: "•", count: min(key.count - 4, 20))
        return prefix + asterisks
    }

    // MARK: - Hold-to-Speak Hotkey

    var holdKeyCode: UInt32 {
        get {
            if defaults.object(forKey: "hold_keycode") != nil {
                return UInt32(defaults.integer(forKey: "hold_keycode"))
            }
            return UInt32(kVK_ANSI_R)
        }
        set { defaults.set(Int(newValue), forKey: "hold_keycode") }
    }

    var holdModifiers: UInt32 {
        get {
            if defaults.object(forKey: "hold_modifiers") != nil {
                return UInt32(defaults.integer(forKey: "hold_modifiers"))
            }
            return UInt32(controlKey | optionKey)
        }
        set { defaults.set(Int(newValue), forKey: "hold_modifiers") }
    }

    var holdDisplayString: String {
        Self.displayString(keyCode: holdKeyCode, carbonModifiers: holdModifiers)
    }

    // MARK: - FreeHand Hotkey

    var freeHandKeyCode: UInt32 {
        get {
            if defaults.object(forKey: "freehand_keycode") != nil {
                return UInt32(defaults.integer(forKey: "freehand_keycode"))
            }
            return UInt32(kVK_ANSI_E)
        }
        set { defaults.set(Int(newValue), forKey: "freehand_keycode") }
    }

    var freeHandModifiers: UInt32 {
        get {
            if defaults.object(forKey: "freehand_modifiers") != nil {
                return UInt32(defaults.integer(forKey: "freehand_modifiers"))
            }
            return UInt32(controlKey | optionKey)
        }
        set { defaults.set(Int(newValue), forKey: "freehand_modifiers") }
    }

    var freeHandDisplayString: String {
        Self.displayString(keyCode: freeHandKeyCode, carbonModifiers: freeHandModifiers)
    }

    // MARK: - Display Helpers

    static func displayString(keyCode: UInt32, carbonModifiers: UInt32) -> String {
        var parts: [String] = []
        if carbonModifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if carbonModifiers & UInt32(optionKey)  != 0 { parts.append("⌥") }
        if carbonModifiers & UInt32(shiftKey)   != 0 { parts.append("⇧") }
        if carbonModifiers & UInt32(cmdKey)     != 0 { parts.append("⌘") }
        parts.append(stringForKeyCode(keyCode))
        return parts.joined()
    }

    static func modifierDisplayString(carbonModifiers: UInt32) -> String {
        var parts: [String] = []
        if carbonModifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if carbonModifiers & UInt32(optionKey)  != 0 { parts.append("⌥") }
        if carbonModifiers & UInt32(shiftKey)   != 0 { parts.append("⇧") }
        if carbonModifiers & UInt32(cmdKey)     != 0 { parts.append("⌘") }
        return parts.joined()
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.option)  { mods |= UInt32(optionKey) }
        if flags.contains(.shift)   { mods |= UInt32(shiftKey) }
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        return mods
    }

    static func stringForKeyCode(_ keyCode: UInt32) -> String {
        // Layout-independent keys (same symbol on every keyboard)
        let fixed: [Int: String] = [
            kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥",
            kVK_Delete: "⌫", kVK_ForwardDelete: "⌦", kVK_Escape: "⎋",
            kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
            kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
            kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
            kVK_UpArrow: "↑", kVK_DownArrow: "↓",
            kVK_LeftArrow: "←", kVK_RightArrow: "→",
        ]
        if let s = fixed[Int(keyCode)] { return s }

        // Character keys → resolve through the user's current keyboard layout
        // (DE, FR, etc.) so "physical Y" on a QWERTZ keyboard shows as "Y".
        if let s = unicodeString(for: keyCode), !s.isEmpty {
            return s.uppercased()
        }

        return "Key\(keyCode)"
    }

    /// Converts a virtual key code into the character it produces on the user's
    /// current keyboard layout (no modifiers applied).
    private static func unicodeString(for keyCode: UInt32) -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue() else {
            return nil
        }
        guard let layoutDataPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }

        let layoutData = Unmanaged<CFData>.fromOpaque(layoutDataPtr).takeUnretainedValue()
        guard let bytePtr = CFDataGetBytePtr(layoutData) else { return nil }

        let keyLayout = UnsafeRawPointer(bytePtr).assumingMemoryBound(to: UCKeyboardLayout.self)

        var deadKeyState: UInt32 = 0
        var chars: [UniChar] = [0, 0, 0, 0]
        var realLength = 0

        let status = UCKeyTranslate(
            keyLayout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDisplay),
            0,                               // no modifiers for display
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            chars.count,
            &realLength,
            &chars
        )

        guard status == noErr, realLength > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: realLength)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let settingsChanged           = Notification.Name("WhisperAI.settingsChanged")
    static let hotkeyTemporarilyDisable  = Notification.Name("WhisperAI.hotkeyDisable")
    static let hotkeyReEnable            = Notification.Name("WhisperAI.hotkeyReEnable")
}
