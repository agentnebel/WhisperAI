import AppKit
import SwiftUI

// MARK: - Settings Root View

private struct SettingsRootView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("Allgemein", systemImage: "gear") }
                .tag(0)

            ModesSettingsView()
                .tabItem { Label("Modus", systemImage: "text.bubble") }
                .tag(1)
        }
        .frame(width: 640, height: 530)
    }
}

// MARK: - Settings Window Controller

class SettingsWindowController: NSWindowController {

    convenience init() {
        let hosting = NSHostingController(rootView: SettingsRootView())

        let window = NSWindow(contentViewController: hosting)
        window.title          = "WhisperAI Einstellungen"
        window.styleMask      = [.titled, .closable, .resizable, .miniaturizable]
        window.setContentSize(NSSize(width: 640, height: 530))
        window.minSize        = NSSize(width: 600, height: 480)
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }
    override init(window: NSWindow?) { super.init(window: window) }

    func showWindow() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
