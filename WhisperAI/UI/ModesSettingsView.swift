import SwiftUI

// MARK: - Modes Settings View

struct ModesSettingsView: View {
    @ObservedObject private var model = WhisperAIModel.shared

    @State private var selectedModeId: UUID?
    @State private var editName   = ""
    @State private var editPrompt = ""
    @State private var savedFeedback = false

    private var selectedMode: Mode? {
        guard let id = selectedModeId else { return nil }
        return model.modes.first { $0.id == id }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            sidebarPane
            Divider()
            editorPane
        }
        .onAppear {
            if selectedModeId == nil {
                selectedModeId = model.activeMode.id
                loadSelectedMode()
            }
        }
    }

    // MARK: - Sidebar

    private var sidebarPane: some View {
        VStack(spacing: 0) {
            List(selection: $selectedModeId) {
                ForEach(model.modes) { mode in
                    ModeRowView(
                        mode: mode,
                        isActive: mode.id == model.activeMode.id
                    )
                    .tag(mode.id)
                }
            }
            .listStyle(.sidebar)
            .onChange(of: selectedModeId) { _ in loadSelectedMode() }

            Divider()

            HStack(spacing: 2) {
                Button(action: addMode) {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .help("Neuen Modus hinzufügen")

                Button(action: removeMode) {
                    Image(systemName: "minus")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .disabled(model.modes.count <= 1)
                .help("Modus löschen")

                Spacer()
            }
            .padding(6)
        }
        .frame(width: 190)
    }

    // MARK: - Editor

    @ViewBuilder
    private var editorPane: some View {
        if selectedMode != nil {
            VStack(spacing: 0) {
                Form {
                    Section("Name") {
                        TextField("Modus-Name", text: $editName)
                            .textFieldStyle(.plain)
                    }
                    Section("Prompt") {
                        TextEditor(text: $editPrompt)
                            .font(.system(.body))
                            .frame(minHeight: 180)
                            .padding(2)
                    }
                }
                .formStyle(.grouped)

                Divider()

                editorBottomBar
            }
        } else {
            Text("Modus auswählen")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var editorBottomBar: some View {
        HStack {
            if savedFeedback {
                Label("Gespeichert", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.callout)
                    .transition(.opacity)
            }
            Spacer()

            let isActive = selectedModeId == model.activeMode.id
            Button("Aktivieren") { activateMode() }
                .buttonStyle(.bordered)
                .disabled(isActive)
                .help(isActive ? "Dieser Modus ist bereits aktiv." : "Diesen Modus aktivieren.")

            Button("Speichern", action: saveMode)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .animation(.easeInOut(duration: 0.2), value: savedFeedback)
    }

    // MARK: - Actions

    private func loadSelectedMode() {
        guard let mode = selectedMode else { return }
        editName   = mode.name
        editPrompt = mode.prompt
    }

    private func addMode() {
        let newMode = Mode(name: "Neuer Modus", prompt: "Gib hier deinen Prompt ein…")
        ModeManager.shared.addMode(newMode)
        model.refreshModes()
        selectedModeId = newMode.id
        loadSelectedMode()
    }

    private func removeMode() {
        guard model.modes.count > 1, let mode = selectedMode else { return }
        let idx = model.modes.firstIndex { $0.id == mode.id } ?? 0
        ModeManager.shared.removeMode(mode)
        model.refreshModes()
        let nextIdx = min(idx, model.modes.count - 1)
        selectedModeId = model.modes[nextIdx].id
        loadSelectedMode()
    }

    private func activateMode() {
        guard let mode = selectedMode else { return }
        model.selectMode(mode)
    }

    private func saveMode() {
        guard let mode = selectedMode else { return }
        let trimName   = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimPrompt = editPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimName.isEmpty, !trimPrompt.isEmpty else { return }

        var updated    = mode
        updated.name   = trimName
        updated.prompt = trimPrompt
        ModeManager.shared.updateMode(updated)
        model.refreshModes()
        NotificationCenter.default.post(name: .settingsChanged, object: nil)

        savedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedFeedback = false
        }
    }
}

// MARK: - Mode Row

private struct ModeRowView: View {
    let mode: Mode
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? Color.accentColor : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle().stroke(
                        isActive ? Color.accentColor : Color(.separatorColor),
                        lineWidth: 1
                    )
                )
            Text(mode.name)
                .font(isActive ? .body.weight(.semibold) : .body)
        }
        .padding(.vertical, 2)
    }
}
