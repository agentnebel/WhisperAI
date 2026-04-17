import Foundation
import Security

/// Dünner Wrapper um die macOS Keychain für generische Passwörter.
/// Verwendet die Login-Keychain des Benutzers.
enum KeychainHelper {
    private static let service = "com.whisperai.app"

    /// Setzt oder überschreibt einen Wert.
    @discardableResult
    static func set(_ value: String, for account: String) -> Bool {
        let data = Data(value.utf8)

        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // Bestehenden Eintrag zuerst löschen, dann neu anlegen.
        SecItemDelete(baseQuery as CFDictionary)

        var attrs = baseQuery
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        let status = SecItemAdd(attrs as CFDictionary, nil)
        if status != errSecSuccess {
            NSLog("WhisperAI: Keychain-Schreibfehler (%@): %d", account, status)
            return false
        }
        return true
    }

    /// Liest einen Wert. Gibt `nil` zurück, wenn kein Eintrag existiert.
    static func get(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                NSLog("WhisperAI: Keychain-Lesefehler (%@): %d", account, status)
            }
            return nil
        }

        guard let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    /// Löscht einen Eintrag (kein Fehler, wenn nicht vorhanden).
    static func delete(_ account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
