import SwiftUI
import AppKit
import Carbon.HIToolbox

// MARK: - Hotkey Slot

enum HotkeySlot { case hold, freeHand }

// MARK: - Hotkey Recorder Model

class HotkeyRecorderModel: ObservableObject {
    let slot: HotkeySlot

    /// The committed hotkey display (what is currently saved in SettingsManager).
    @Published var displayString: String
    /// Non-nil while recording: shows modifier hints ("⌃⌥…") or the captured combo ("⌃⌥R").
    @Published var pendingDisplay: String?
    @Published var isRecording = false

    private(set) var pendingKeyCode: UInt32?
    private(set) var pendingModifiers: UInt32?
    private var monitor: Any?

    init(slot: HotkeySlot) {
        self.slot = slot
        self.displayString = slot == .hold
            ? SettingsManager.shared.holdDisplayString
            : SettingsManager.shared.freeHandDisplayString
    }

    deinit { removeMonitor() }

    // MARK: - Public

    func toggle() {
        if isRecording { cancelRecording() } else { startRecording() }
    }

    /// Persist the pending combo to SettingsManager (called on Save).
    func commit() {
        guard let kc = pendingKeyCode, let mods = pendingModifiers else { return }
        if slot == .hold {
            SettingsManager.shared.holdKeyCode   = kc
            SettingsManager.shared.holdModifiers = mods
        } else {
            SettingsManager.shared.freeHandKeyCode   = kc
            SettingsManager.shared.freeHandModifiers = mods
        }
        displayString  = slot == .hold
            ? SettingsManager.shared.holdDisplayString
            : SettingsManager.shared.freeHandDisplayString
        pendingDisplay = nil
        pendingKeyCode = nil
        pendingModifiers = nil
    }

    func cancelRecording() {
        isRecording  = false
        pendingDisplay   = nil
        pendingKeyCode   = nil
        pendingModifiers = nil
        removeMonitor()
        NotificationCenter.default.post(name: .hotkeyReEnable, object: nil)
    }

    // MARK: - Private

    private func startRecording() {
        isRecording    = true
        pendingDisplay = nil
        NotificationCenter.default.post(name: .hotkeyTemporarilyDisable, object: nil)

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) {
            [weak self] event in
            guard let self, self.isRecording else { return event }

            if event.type == .flagsChanged {
                let nsFlags   = event.modifierFlags.intersection([.control, .option, .command, .shift])
                let carbonMods = SettingsManager.carbonModifiers(from: nsFlags)
                DispatchQueue.main.async {
                    self.pendingDisplay = carbonMods != 0
                        ? SettingsManager.modifierDisplayString(carbonModifiers: carbonMods) + "…"
                        : nil
                }
                return nil
            }

            // Escape → cancel
            if event.keyCode == UInt16(kVK_Escape) {
                DispatchQueue.main.async { self.cancelRecording() }
                return nil
            }

            let nsFlags    = event.modifierFlags.intersection([.control, .option, .command, .shift])
            let carbonMods = SettingsManager.carbonModifiers(from: nsFlags)
            guard carbonMods != 0 else { return nil }   // require at least one modifier

            let kc      = UInt32(event.keyCode)
            let display = SettingsManager.displayString(keyCode: kc, carbonModifiers: carbonMods)

            DispatchQueue.main.async {
                self.pendingDisplay  = display
                self.pendingKeyCode   = kc
                self.pendingModifiers = carbonMods
                self.isRecording     = false
                self.removeMonitor()
                NotificationCenter.default.post(name: .hotkeyReEnable, object: nil)
            }
            return nil
        }
    }

    private func removeMonitor() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @StateObject private var holdRecorder     = HotkeyRecorderModel(slot: .hold)
    @StateObject private var freeHandRecorder = HotkeyRecorderModel(slot: .freeHand)

    @State private var isEditingApiKey = false
    @State private var apiKeyInput     = ""
    @State private var savedFeedback   = false
    @FocusState private var apiKeyFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Form {
                apiKeySection
                holdSection
                freeHandSection
            }
            .formStyle(.grouped)

            Divider()

            bottomBar
        }
    }

    // MARK: - API Key Section

    private var apiKeySection: some View {
        Section {
            if isEditingApiKey {
                TextField("sk-…", text: $apiKeyInput)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.plain)
                    .padding(.vertical, 2)
                    .focused($apiKeyFocused)
                Text("Füge deinen OpenAI API Key ein (⌘V) und klicke Speichern.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                LabeledContent("API Key") {
                    HStack {
                        Text(SettingsManager.shared.maskedApiKey)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Ändern") {
                            apiKeyInput = SettingsManager.shared.apiKey
                            isEditingApiKey = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                apiKeyFocused = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        } header: {
            Text("OpenAI API Key")
        }
    }

    // MARK: - Hold-to-Speak Section

    private var holdSection: some View {
        Section {
            HotkeyRowView(recorder: holdRecorder)
        } header: {
            Text("Hold-to-Speak")
        } footer: {
            Text("Taste gedrückt halten → sprechen → loslassen beendet die Aufnahme.")
        }
    }

    // MARK: - FreeHand Section

    private var freeHandSection: some View {
        Section {
            HotkeyRowView(recorder: freeHandRecorder)
        } header: {
            Text("FreeHand")
        } footer: {
            Text("Einmal drücken = Aufnahme starten · erneut drücken = Aufnahme stoppen.")
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if savedFeedback {
                Label("Gespeichert", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.callout)
                    .transition(.opacity)
            }
            Spacer()
            Button("Speichern", action: save)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .animation(.easeInOut(duration: 0.2), value: savedFeedback)
    }

    // MARK: - Actions

    private func save() {
        if isEditingApiKey {
            let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { SettingsManager.shared.apiKey = trimmed }
            apiKeyInput     = ""
            isEditingApiKey = false
        }

        holdRecorder.commit()
        freeHandRecorder.commit()

        NotificationCenter.default.post(name: .settingsChanged, object: nil)

        savedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedFeedback = false
        }
    }
}

// MARK: - Hotkey Row View

struct HotkeyRowView: View {
    @ObservedObject var recorder: HotkeyRecorderModel

    private var displayedShortcut: String {
        if let pending = recorder.pendingDisplay { return pending }
        if recorder.isRecording { return "Warte auf Eingabe…" }
        return recorder.displayString
    }

    var body: some View {
        LabeledContent("Tastenkürzel") {
            HStack(spacing: 10) {
                Text(displayedShortcut)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(recorder.isRecording ? .orange : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(
                                recorder.isRecording ? Color.orange : Color(.separatorColor),
                                lineWidth: recorder.isRecording ? 1.5 : 1
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(.controlBackgroundColor))
                            )
                    )
                    .animation(.easeInOut(duration: 0.15), value: recorder.isRecording)

                Button(recorder.isRecording ? "Abbrechen" : "Aufnehmen") {
                    recorder.toggle()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}
