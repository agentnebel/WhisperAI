import AppKit
import Combine

/// Observable bridge between AppKit state and SwiftUI views.
/// AppDelegate writes to it; SwiftUI views read and react.
class WhisperAIModel: ObservableObject {
    static let shared = WhisperAIModel()

    @Published var appState: AppState = .idle
    @Published var activeMode: Mode = ModeManager.shared.activeMode
    @Published var modes: [Mode] = ModeManager.shared.modes

    /// Called when the user taps "Einstellungen…" in the popover.
    var onOpenSettings: (() -> Void)?
    /// Called when the user taps "Beenden" in the popover.
    var onQuit: (() -> Void)?

    private init() {}

    // MARK: - Public API

    func selectMode(_ mode: Mode) {
        ModeManager.shared.setActiveMode(mode)
        activeMode = mode
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }

    /// Syncs published properties from ModeManager (call after external changes).
    func refreshModes() {
        modes = ModeManager.shared.modes
        activeMode = ModeManager.shared.activeMode
    }
}
