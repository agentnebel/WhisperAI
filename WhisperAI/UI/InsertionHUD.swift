import AppKit
import QuartzCore

/// Kleines HUD-Overlay, das kurz erscheint wenn Text eingefügt wird.
/// Zeigt einen animierten Fortschrittsbalken und dann ein Checkmark.
final class InsertionHUD {

    // MARK: - Shared

    static let shared = InsertionHUD()
    private init() {}

    // MARK: - Private State

    private var window: NSWindow?
    private var hideWorkItem: DispatchWorkItem?

    // MARK: - Public API

    /// Zeigt das HUD mit "Verarbeitung…" an (während LLM läuft).
    func showProcessing(modeName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.present(icon: "ellipsis.circle.fill",
                          iconColor: .systemOrange,
                          title: "Verarbeitung…",
                          subtitle: modeName,
                          autohide: false)
        }
    }

    /// Wechselt das HUD zu "Text eingefügt ✓" und versteckt es danach.
    func showDone(modeName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.present(icon: "checkmark.circle.fill",
                          iconColor: .systemGreen,
                          title: "Text eingefügt",
                          subtitle: modeName,
                          autohide: true)
        }
    }

    /// Versteckt das HUD sofort (z.B. bei Fehler).
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss()
        }
    }

    // MARK: - Private

    private func present(icon: String, iconColor: NSColor, title: String, subtitle: String, autohide: Bool) {
        hideWorkItem?.cancel()
        hideWorkItem = nil

        if window == nil { window = makeWindow() }
        guard let window, let content = window.contentView else { return }

        // Update content
        updateContent(in: content, icon: icon, iconColor: iconColor, title: title, subtitle: subtitle)

        // Position: bottom-center of main screen
        if let screen = NSScreen.main {
            let sw = screen.visibleFrame
            let ww = window.frame.width
            let x = sw.minX + (sw.width - ww) / 2
            let y = sw.minY + 60
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        if !window.isVisible {
            window.alphaValue = 0
            window.orderFront(nil)
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                window.animator().alphaValue = 1
            }
        }

        if autohide {
            let item = DispatchWorkItem { [weak self] in self?.dismiss() }
            hideWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: item)
        }
    }

    private func dismiss() {
        guard let window, window.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
        })
    }

    private func makeWindow() -> NSWindow {
        let w = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 62),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        w.level = .floating
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = true
        w.ignoresMouseEvents = true
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let background = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 240, height: 62))
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        // Apple-empfohlener Weg für abgerundete Blur-Views:
        // maskImage statt layer.cornerRadius (letzteres ignoriert die Transparenz
        // bei .behindWindow und hinterlässt milchige Ecken).
        background.maskImage = Self.roundedMaskImage(cornerRadius: 14)

        w.contentView = background
        return w
    }

    /// Erzeugt ein stretchbares Rounded-Rect als Maskenbild für NSVisualEffectView.
    private static func roundedMaskImage(cornerRadius: CGFloat) -> NSImage {
        let edge = 2 * cornerRadius + 1
        let size = NSSize(width: edge, height: edge)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.set()
            NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: cornerRadius, left: cornerRadius,
                                       bottom: cornerRadius, right: cornerRadius)
        image.resizingMode = .stretch
        return image
    }

    private func updateContent(in view: NSView, icon: String, iconColor: NSColor, title: String, subtitle: String) {
        // Remove old subviews
        view.subviews.forEach { if !($0 is NSVisualEffectView) { $0.removeFromSuperview() } }

        let bounds = view.bounds

        // Icon
        let iconView = NSImageView(frame: NSRect(x: 14, y: (bounds.height - 30) / 2, width: 30, height: 30))
        if let img = NSImage(systemSymbolName: icon, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 22, weight: .medium)
            iconView.image = img.withSymbolConfiguration(config)
        }
        iconView.contentTintColor = iconColor
        view.addSubview(iconView)

        // Title
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.sizeToFit()
        titleLabel.frame.origin = NSPoint(x: 52, y: bounds.height / 2 + 1)
        view.addSubview(titleLabel)

        // Subtitle
        let subLabel = NSTextField(labelWithString: subtitle)
        subLabel.font = .systemFont(ofSize: 11, weight: .regular)
        subLabel.textColor = .secondaryLabelColor
        subLabel.sizeToFit()
        subLabel.frame.origin = NSPoint(x: 52, y: bounds.height / 2 - subLabel.frame.height - 1)
        view.addSubview(subLabel)
    }
}
