import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var holdHotkeyManager: HotkeyManager!
    private var freeHandHotkeyManager: HotkeyManager!
    private var audioRecorder: AudioRecorder!
    private var settingsWindowController: SettingsWindowController?

    private var state: AppState = .idle {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.statusBarController.updateIcon(for: self.state)
                WhisperAIModel.shared.appState = self.state
            }
        }
    }

    // MARK: - App Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        audioRecorder = AudioRecorder()

        statusBarController = StatusBarController()
        statusBarController.onOpenSettings = { [weak self] in
            self?.openSettings()
        }
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }

        setupHotkeyManagers()
        setupNotifications()

        Task {
            let micGranted = await AudioRecorder.requestPermission()
            // Show our custom alert only once (macOS shows its own system dialog on first request)
            if !micGranted {
                let alreadyAlerted = UserDefaults.standard.bool(forKey: "microphoneAlertShown")
                if !alreadyAlerted {
                    UserDefaults.standard.set(true, forKey: "microphoneAlertShown")
                    await MainActor.run {
                        showAlert(
                            title: "Mikrofon-Zugriff",
                            message: "WhisperAI benötigt Mikrofonzugriff. Bitte aktivieren unter Systemeinstellungen → Datenschutz & Sicherheit → Mikrofon."
                        )
                    }
                }
            } else {
                // Granted — reset flag so a future revoke triggers the alert again
                UserDefaults.standard.removeObject(forKey: "microphoneAlertShown")
            }
        }

        let accessibilityGranted = TextInserter.checkAndRequest()
        if !accessibilityGranted {
            // Show step-by-step onboarding (only once, in system language)
            AccessibilityOnboarding.showIfNeeded()
            // After onboarding might have been dismissed, check once if user already granted
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.checkAccessibilityAfterGrant()
            }
        }

        if SettingsManager.shared.apiKey.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.openSettings()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        holdHotkeyManager.unregister()
        freeHandHotkeyManager.unregister()
    }

    // MARK: - Main Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut",        action: #selector(NSText.cut(_:)),       keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy",       action: #selector(NSText.copy(_:)),      keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste",      action: #selector(NSText.paste(_:)),     keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
        NSApp.mainMenu = mainMenu
    }

    // MARK: - Hotkey Setup

    private func setupHotkeyManagers() {
        let sm = SettingsManager.shared

        // ID 1 = Hold-to-Speak
        holdHotkeyManager = HotkeyManager(keyCode: sm.holdKeyCode, modifiers: sm.holdModifiers, id: 1)
        holdHotkeyManager.onKeyDown = { [weak self] in
            DispatchQueue.main.async { self?.holdKeyDown() }
        }
        holdHotkeyManager.onKeyUp = { [weak self] in
            DispatchQueue.main.async { self?.holdKeyUp() }
        }
        holdHotkeyManager.register()

        // ID 2 = FreeHand
        freeHandHotkeyManager = HotkeyManager(keyCode: sm.freeHandKeyCode, modifiers: sm.freeHandModifiers, id: 2)
        freeHandHotkeyManager.onKeyDown = { [weak self] in
            DispatchQueue.main.async { self?.freeHandKeyDown() }
        }
        freeHandHotkeyManager.register()
    }

    private func holdKeyDown() {
        if state == .idle { startRecording() }
    }

    private func holdKeyUp() {
        if state == .recording { stopAndProcess() }
    }

    private func freeHandKeyDown() {
        switch state {
        case .idle:      startRecording()
        case .recording: stopAndProcess()
        case .processing: break
        }
    }

    // MARK: - Notifications

    private func setupNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(onSettingsChanged),  name: .settingsChanged,          object: nil)
        nc.addObserver(self, selector: #selector(onHotkeyDisable),    name: .hotkeyTemporarilyDisable, object: nil)
        nc.addObserver(self, selector: #selector(onHotkeyReEnable),   name: .hotkeyReEnable,           object: nil)
    }

    @objc private func onSettingsChanged() {
        let sm = SettingsManager.shared
        holdHotkeyManager.reregister(keyCode: sm.holdKeyCode, modifiers: sm.holdModifiers)
        freeHandHotkeyManager.reregister(keyCode: sm.freeHandKeyCode, modifiers: sm.freeHandModifiers)
        statusBarController.rebuildMenu()
    }

    @objc private func onHotkeyDisable() {
        holdHotkeyManager.unregister()
        freeHandHotkeyManager.unregister()
    }

    @objc private func onHotkeyReEnable() {
        holdHotkeyManager.register()
        freeHandHotkeyManager.register()
    }

    // MARK: - Recording

    private func startRecording() {
        guard !SettingsManager.shared.apiKey.isEmpty else {
            NSLog("WhisperAI: Kein API Key gesetzt")
            openSettings()
            return
        }
        do {
            try audioRecorder.startRecording()
            state = .recording
            NSLog("WhisperAI: Aufnahme gestartet")
            NSSound.beep()
        } catch {
            NSLog("WhisperAI: Aufnahme-Fehler: %@", error.localizedDescription)
            showAlert(title: "Fehler", message: error.localizedDescription)
        }
    }

    private func stopAndProcess() {
        guard let audioURL = audioRecorder.stopRecording() else {
            NSLog("WhisperAI: Keine Audiodatei vorhanden")
            state = .idle
            return
        }

        NSLog("WhisperAI: Aufnahme gestoppt, Datei: %@", audioURL.path)
        state = .processing

        let apiKey = SettingsManager.shared.apiKey
        // Snapshot aktiver Modus zum Zeitpunkt der Aufnahme
        let mode   = ModeManager.shared.activeMode
        NSLog("WhisperAI: Modus aktiv: %@", mode.name)

        InsertionHUD.shared.showProcessing(modeName: mode.name)

        Task {
            do {
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: audioURL.path))?[.size] as? Int ?? 0
                NSLog("WhisperAI: Audiodatei %d bytes", fileSize)

                let whisper = WhisperService(apiKey: apiKey)
                let transcript = try await whisper.transcribe(audioURL: audioURL)
                // Datenschutz: nur Länge loggen, keine Inhalte in Systemlogs schreiben
                NSLog("WhisperAI: Transkript erhalten (%d Zeichen)", transcript.count)

                let llm = LLMService(apiKey: apiKey)
                let result = try await llm.process(transcript: transcript, systemPrompt: mode.prompt)
                NSLog("WhisperAI: LLM-Ergebnis erhalten (%d Zeichen)", result.count)

                await MainActor.run {
                    InsertionHUD.shared.showDone(modeName: mode.name)
                    TextInserter.insert(text: result)
                    self.state = .idle
                }
            } catch {
                NSLog("WhisperAI: Pipeline-Fehler: %@", error.localizedDescription)
                await MainActor.run {
                    InsertionHUD.shared.hide()
                    self.showAlert(title: "Fehler", message: error.localizedDescription)
                    self.state = .idle
                }
            }
            try? FileManager.default.removeItem(at: audioURL)
        }
    }

    // MARK: - Accessibility

    private func checkAccessibilityAfterGrant() {
        guard AXIsProcessTrusted() else { return }
        let alert = NSAlert()
        alert.messageText = "Berechtigung erteilt — Neustart erforderlich"
        alert.informativeText = "Die Bedienungshilfen-Berechtigung wurde erteilt. WhisperAI muss einmal neu gestartet werden, damit das automatische Einfügen funktioniert."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Jetzt neu starten")
        alert.addButton(withTitle: "Später")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = [Bundle.main.bundleURL.path]
            try? task.run()
            NSApp.terminate(nil)
        }
    }

    // MARK: - Settings

    private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow()
    }

    // MARK: - Alerts

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
