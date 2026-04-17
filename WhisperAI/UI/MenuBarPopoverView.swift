import SwiftUI

// MARK: - Popover Root

struct MenuBarPopoverView: View {
    @ObservedObject private var model = WhisperAIModel.shared
    @State private var shortcutsRefreshToken = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Divider()

            modeSection
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            shortcutsSection
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            actionsSection
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .frame(width: 290)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.title3.weight(.medium))
                .foregroundColor(.accentColor)

            Text("WhisperAI")
                .font(.headline)

            Spacer()

            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(statusLabel)
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color(.windowBackgroundColor).opacity(0.6))
        .overlay(
            Capsule()
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch model.appState {
        case .idle:       return .green
        case .recording:  return .red
        case .processing: return .orange
        }
    }

    private var statusLabel: String {
        switch model.appState {
        case .idle:       return "Bereit"
        case .recording:  return "Aufnahme"
        case .processing: return "Verarbeitung"
        }
    }

    // MARK: - Mode Section

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Modus")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 2) {
                ForEach(model.modes) { mode in
                    ModeRowButton(
                        mode: mode,
                        isActive: mode.id == model.activeMode.id
                    ) {
                        model.selectMode(mode)
                    }
                }
            }
        }
    }

    // MARK: - Shortcuts Section

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Tastenkürzel")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ShortcutRow(label: "Hold-to-Speak",
                        shortcut: SettingsManager.shared.holdDisplayString)
            ShortcutRow(label: "FreeHand",
                        shortcut: SettingsManager.shared.freeHandDisplayString)
        }
        .id(shortcutsRefreshToken)
        .onReceive(NotificationCenter.default.publisher(for: .settingsChanged)) { _ in
            shortcutsRefreshToken = UUID()
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 0) {
            PopoverActionButton(icon: "gear",   title: "Einstellungen…") {
                model.onOpenSettings?()
            }
            PopoverActionButton(icon: "power",  title: "Beenden") {
                model.onQuit?()
            }
        }
    }
}

// MARK: - Mode Row Button

private struct ModeRowButton: View {
    let mode: Mode
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Aktiv-Indikator
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: isActive ? .medium : .regular))
                    .foregroundColor(isActive ? .accentColor : Color(.tertiaryLabelColor))
                    .frame(width: 16)

                Text(mode.name)
                    .font(.callout)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(isActive ? .primary : .primary)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isActive
                          ? Color.accentColor.opacity(0.12)
                          : isHovered ? Color(.selectedContentBackgroundColor).opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Shortcut Row

private struct ShortcutRow: View {
    let label: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundColor(.primary)
            Spacer()
            Text(shortcut)
                .font(.system(.callout, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(5)
        }
    }
}

// MARK: - Popover Action Button

private struct PopoverActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .font(.callout)
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color(.selectedContentBackgroundColor).opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
