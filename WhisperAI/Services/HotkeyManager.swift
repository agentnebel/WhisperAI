import Carbon
import Cocoa

/// Verwaltet einen einzelnen globalen Hotkey. Mehrere Instanzen teilen sich
/// einen gemeinsamen Carbon-Event-Handler, der per ID zur richtigen Instanz
/// dispatcht. Dadurch wird jedes Hotkey-Event garantiert nur einmal verarbeitet.
class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?

    var keyCode: UInt32
    var modifiers: UInt32
    private let hotKeyID: UInt32  // unique ID to distinguish multiple instances

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    // MARK: - Shared Dispatcher (app-wide, installed once)

    private static var instances: [UInt32: HotkeyManager] = [:]
    private static var sharedHandlerRef: EventHandlerRef?

    init(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.hotKeyID = id
    }

    // MARK: - Register / Unregister

    func register() {
        unregister()
        HotkeyManager.instances[hotKeyID] = self
        HotkeyManager.ensureSharedHandlerInstalled()

        let hkID = EventHotKeyID(signature: OSType(0x57484149), id: hotKeyID)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hkID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            NSLog("WhisperAI: Hotkey %d Registrierung fehlgeschlagen: %d", hotKeyID, status)
        } else {
            NSLog("WhisperAI: Hotkey %d registriert (keyCode=%d, modifiers=%d)", hotKeyID, keyCode, modifiers)
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        HotkeyManager.instances.removeValue(forKey: hotKeyID)
        // Shared handler bleibt installiert — andere Instanzen können ihn weiter nutzen.
    }

    func reregister(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        register()
    }

    deinit {
        unregister()
    }

    // MARK: - Shared Handler

    private static func ensureSharedHandlerInstalled() {
        guard sharedHandlerRef == nil else { return }

        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]

        let callback: EventHandlerUPP = { _, inEvent, _ -> OSStatus in
            guard let event = inEvent else { return OSStatus(eventNotHandledErr) }

            var hkID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hkID
            )

            let manager = HotkeyManager.instances[hkID.id]
            let kind = GetEventKind(event)
            if kind == UInt32(kEventHotKeyPressed) {
                NSLog("WhisperAI: Hotkey %d gedrückt", hkID.id)
                manager?.onKeyDown?()
            } else if kind == UInt32(kEventHotKeyReleased) {
                NSLog("WhisperAI: Hotkey %d losgelassen", hkID.id)
                manager?.onKeyUp?()
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            2,
            &eventTypes,
            nil,
            &sharedHandlerRef
        )
    }
}
