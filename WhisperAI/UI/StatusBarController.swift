import AppKit
import SwiftUI

class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private var popover: NSPopover!
    private var eventMonitor: Any?

    // MARK: - Callbacks (wired by AppDelegate)

    /// Kept for API compatibility; mode selection is now handled by SwiftUI directly.
    var onModeSelected: ((Mode) -> Void)?

    var onOpenSettings: (() -> Void)? {
        didSet {
            // Wrap: close popover first, then open settings window.
            let action = onOpenSettings
            WhisperAIModel.shared.onOpenSettings = { [weak self] in
                self?.closePopover()
                action?()
            }
        }
    }

    var onQuit: (() -> Void)? {
        didSet {
            WhisperAIModel.shared.onQuit = onQuit
        }
    }

    // MARK: - Init

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupPopover()
        updateIcon(for: .idle)
    }

    // MARK: - Popover Setup

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 290, height: 400) // wird von sizingOptions überschrieben
        popover.behavior    = .applicationDefined  // we control close manually
        popover.animates    = true

        // Wichtig: NSHostingController muss die SwiftUI-Intrinsicsize ans NSPopover
        // weitergeben, sonst bleibt contentSize fix und der Inhalt wird abgeschnitten.
        let hosting = NSHostingController(rootView: MenuBarPopoverView())
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = [.preferredContentSize]
        }
        popover.contentViewController = hosting

        guard let button = statusItem.button else { return }
        button.action = #selector(togglePopover(_:))
        button.target = self
    }

    // MARK: - Toggle

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            closePopover()
        } else {
            openPopover(relativeTo: sender)
        }
    }

    private func openPopover(relativeTo button: NSStatusBarButton) {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Add the global-click monitor on the next run-loop tick so the
        // current mouse-down event doesn't immediately close the popover.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.popover.isShown else { return }
            self.eventMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            ) { [weak self] _ in
                self?.closePopover()
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Icon Updates (called by AppDelegate)

    func updateIcon(for state: AppState) {
        guard let button = statusItem.button else { return }

        let symbolName: String
        switch state {
        case .idle:
            symbolName = "waveform"
            button.contentTintColor = nil
        case .recording:
            symbolName = "mic.fill"
            button.contentTintColor = .systemRed
        case .processing:
            symbolName = "ellipsis.circle"
            button.contentTintColor = .systemOrange
        }

        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "WhisperAI")
    }

    // MARK: - Legacy Compatibility

    /// No-op: SwiftUI popover updates reactively; call this to sync the model.
    func rebuildMenu() {
        WhisperAIModel.shared.refreshModes()
    }
}
