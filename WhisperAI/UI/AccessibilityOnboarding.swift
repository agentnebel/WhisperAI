import AppKit
import ServiceManagement

/// Zeigt beim ersten Start eine schrittweise Anleitung zur Vergabe der
/// Bedienungshilfen-Berechtigung sowie einen optionalen Autostart-Hinweis,
/// jeweils in der Systemsprache des Benutzers.
final class AccessibilityOnboarding {

    // MARK: - Localized Strings

    struct Strings {
        let title: String
        let subtitle: String
        let steps: [String]
        let pathHint: String
        let autostartTitle: String
        let autostartDescription: String
        let autostartButton: String
        let openButton: String
        let dismissButton: String

        static func forCurrentLocale() -> Strings {
            let lang = Locale.preferredLanguages.first?.prefix(2) ?? "en"
            switch lang {
            case "de":
                return Strings(
                    title: "Berechtigung erforderlich",
                    subtitle: "WhisperAI ben\u{00F6}tigt Zugriff auf die Bedienungshilfen,\num Text automatisch in andere Apps einzuf\u{00FC}gen.",
                    steps: [
                        "1  Klicke auf \u{201E}Einstellungen \u{00F6}ffnen\u{201C} unten.",
                        "2  Scrolle zu WhisperAI in der Liste.",
                        "3  Aktiviere den Schalter neben WhisperAI.",
                        "4  Starte WhisperAI neu \u{2013} fertig! \u{2713}"
                    ],
                    pathHint: "Systemeinstellungen \u{2192} Datenschutz & Sicherheit \u{2192} Bedienungshilfen",
                    autostartTitle: "Autostart (optional)",
                    autostartDescription: "WhisperAI automatisch beim Anmelden starten. Klicke unten \u{2013} die App tr\u{00E4}gt sich selbst in \u{201E}Anmeldeobjekte & Erweiterungen\u{201C} ein.",
                    autostartButton: "Autostart aktivieren",
                    openButton: "Einstellungen\u{2026}",
                    dismissButton: "Sp\u{00E4}ter"
                )
            case "fr":
                return Strings(
                    title: "Autorisation requise",
                    subtitle: "WhisperAI a besoin d'acc\u{00E9}der aux fonctionnalit\u{00E9}s d'accessibilit\u{00E9}\npour ins\u{00E9}rer du texte dans d'autres applications.",
                    steps: [
                        "1  Cliquez sur \u{00AB} Ouvrir les r\u{00E9}glages \u{00BB} ci-dessous.",
                        "2  Faites d\u{00E9}filer jusqu'\u{00E0} WhisperAI dans la liste.",
                        "3  Activez le commutateur \u{00E0} c\u{00F4}t\u{00E9} de WhisperAI.",
                        "4  Relancez WhisperAI \u{2013} c'est fait ! \u{2713}"
                    ],
                    pathHint: "R\u{00E9}glages Syst\u{00E8}me \u{2192} Confidentialit\u{00E9} et s\u{00E9}curit\u{00E9} \u{2192} Accessibilit\u{00E9}",
                    autostartTitle: "D\u{00E9}marrage automatique (optionnel)",
                    autostartDescription: "Lancer WhisperAI automatiquement \u{00E0} la connexion. Cliquez ci-dessous \u{2013} l'application s'inscrit elle-m\u{00EA}me dans les \u{00E9}l\u{00E9}ments d'ouverture.",
                    autostartButton: "Activer le d\u{00E9}marrage automatique",
                    openButton: "Ouvrir les r\u{00E9}glages",
                    dismissButton: "Plus tard"
                )
            default:
                return Strings(
                    title: "Permission Required",
                    subtitle: "WhisperAI needs Accessibility access\nto automatically paste text into other apps.",
                    steps: [
                        "1  Click \u{201C}Open Settings\u{201D} below.",
                        "2  Scroll to WhisperAI in the list.",
                        "3  Enable the toggle next to WhisperAI.",
                        "4  Restart WhisperAI \u{2013} you're all set! \u{2713}"
                    ],
                    pathHint: "System Settings \u{2192} Privacy & Security \u{2192} Accessibility",
                    autostartTitle: "Auto-start (optional)",
                    autostartDescription: "Launch WhisperAI automatically when you log in. Click below \u{2013} the app registers itself in Login Items & Extensions.",
                    autostartButton: "Enable Auto-start",
                    openButton: "Open Settings",
                    dismissButton: "Later"
                )
            }
        }
    }

    // MARK: - Public Entry Point

    static func showIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            PanelController.shared.show()
        }
    }
}

// MARK: - PanelController (owns the panel, survives button taps)

/// Langlebiger Controller der das Panel stark hält und Button-Aktionen besitzt.
/// Wird statisch gehalten → kein weak-target-Deallocating-Problem.
private final class PanelController: NSObject {

    static let shared = PanelController()
    private var panel: NSPanel?
    private var autostartButton: NSButton?

    func show() {
        let s = AccessibilityOnboarding.Strings.forCurrentLocale()

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 470),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.title = "WhisperAI"
        p.level = .floating
        p.isReleasedWhenClosed = false
        p.center()
        self.panel = p

        let content = NSView(frame: p.contentView!.bounds)
        content.autoresizingMask = [.width, .height]

        // App Icon
        let iconView = NSImageView(frame: NSRect(x: 20, y: 390, width: 52, height: 52))
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        content.addSubview(iconView)

        // Title
        content.addSubview(label(s.title,
            font: .systemFont(ofSize: 17, weight: .bold),
            frame: NSRect(x: 82, y: 416, width: 380, height: 22)))

        // Subtitle
        content.addSubview(label(s.subtitle,
            font: .systemFont(ofSize: 12.5),
            color: .secondaryLabelColor,
            frame: NSRect(x: 82, y: 378, width: 380, height: 36)))

        // Divider
        let div = NSBox(frame: NSRect(x: 20, y: 364, width: 440, height: 1))
        div.boxType = .separator
        content.addSubview(div)

        // Steps box (Accessibility)
        let box = NSBox(frame: NSRect(x: 20, y: 230, width: 440, height: 126))
        box.boxType = .custom
        box.fillColor   = .controlBackgroundColor
        box.borderColor = .separatorColor
        box.cornerRadius = 10
        box.borderWidth  = 1
        content.addSubview(box)

        var stepY: CGFloat = 310
        for step in s.steps {
            content.addSubview(label(step,
                font: .systemFont(ofSize: 13),
                frame: NSRect(x: 36, y: stepY, width: 408, height: 18)))
            stepY -= 27
        }

        // Path hint
        let hint = label(s.pathHint,
            font: .systemFont(ofSize: 10.5),
            color: .tertiaryLabelColor,
            frame: NSRect(x: 20, y: 208, width: 440, height: 16))
        hint.alignment = .center
        content.addSubview(hint)

        // Divider between Accessibility and Autostart sections
        let div2 = NSBox(frame: NSRect(x: 20, y: 186, width: 440, height: 1))
        div2.boxType = .separator
        content.addSubview(div2)

        // Autostart section title
        content.addSubview(label(s.autostartTitle,
            font: .systemFont(ofSize: 13, weight: .semibold),
            frame: NSRect(x: 20, y: 158, width: 440, height: 18)))

        // Autostart description
        content.addSubview(label(s.autostartDescription,
            font: .systemFont(ofSize: 12),
            color: .secondaryLabelColor,
            frame: NSRect(x: 20, y: 116, width: 440, height: 40)))

        // Autostart button (registers app as Login Item programmatically)
        autostartButton = NSButton(title: s.autostartButton, target: self, action: #selector(toggleAutostart))
        autostartButton?.frame = NSRect(x: 20, y: 78, width: 260, height: 28)
        autostartButton?.bezelStyle = NSButton.BezelStyle.rounded
        autostartButton?.controlSize = .small
        content.addSubview(autostartButton!)
        refreshAutostartButton()

        // "Später" button — self is the target (strongly retained)
        let dismissBtn = NSButton(title: s.dismissButton, target: self, action: #selector(dismiss))
        dismissBtn.frame = NSRect(x: 258, y: 20, width: 92, height: 32)
        dismissBtn.bezelStyle = NSButton.BezelStyle.rounded
        dismissBtn.keyEquivalent = "\u{1b}"
        content.addSubview(dismissBtn)

        // "Einstellungen öffnen" button — self is the target
        let openBtn = NSButton(title: s.openButton, target: self, action: #selector(openSettings))
        openBtn.frame = NSRect(x: 355, y: 20, width: 105, height: 32)
        openBtn.bezelStyle = NSButton.BezelStyle.rounded
        openBtn.keyEquivalent = "\r"
        content.addSubview(openBtn)

        p.contentView?.addSubview(content)
        NSApp.activate(ignoringOtherApps: true)
        p.makeKeyAndOrderFront(nil)
    }

    @objc func dismiss() {
        panel?.close()
        panel = nil
    }

    @objc func openSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        dismiss()
    }

    @objc func toggleAutostart() {
        guard #available(macOS 13.0, *) else {
            // Fallback for macOS 12 and older: open the Login Items settings pane
            openLoginItemsSettings()
            return
        }

        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
                NSLog("WhisperAI: Autostart deaktiviert")
            } else {
                try service.register()
                NSLog("WhisperAI: Autostart aktiviert")
            }
            refreshAutostartButton()
        } catch {
            NSLog("WhisperAI: SMAppService-Fehler: %@", error.localizedDescription)
            // Fallback: let the user enable it manually in System Settings
            openLoginItemsSettings()
        }
    }

    /// Synchronisiert die Beschriftung des Autostart-Buttons mit dem realen Status.
    private func refreshAutostartButton() {
        guard let button = autostartButton else { return }
        let s = AccessibilityOnboarding.Strings.forCurrentLocale()

        if #available(macOS 13.0, *), SMAppService.mainApp.status == .enabled {
            button.title = Self.disableAutostartTitle(for: s)
        } else {
            button.title = s.autostartButton
        }
    }

    private static func disableAutostartTitle(for s: AccessibilityOnboarding.Strings) -> String {
        // Lokale, einfache Heuristik — reicht für die drei unterstützten Sprachen.
        let lang = Locale.preferredLanguages.first?.prefix(2) ?? "en"
        switch lang {
        case "de": return "Autostart deaktivieren"
        case "fr": return "D\u{00E9}sactiver le d\u{00E9}marrage automatique"
        default:   return "Disable Auto-start"
        }
    }

    private func openLoginItemsSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Label helper

    private func label(_ text: String,
                       font: NSFont,
                       color: NSColor = .labelColor,
                       frame: NSRect) -> NSTextField {
        let f = NSTextField(labelWithString: text)
        f.frame = frame
        f.font  = font
        f.textColor = color
        f.lineBreakMode = .byWordWrapping
        f.maximumNumberOfLines = 4
        return f
    }
}
