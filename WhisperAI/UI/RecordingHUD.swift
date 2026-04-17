import AppKit
import QuartzCore

/// Zentriertes Aufnahme-Overlay: erscheint beim Start einer Aufnahme
/// und verschwindet wenn die Aufnahme endet.
/// Zeigt ein pulsierendes Mikrofon-Symbol auf einem transparenten
/// Frosted-Glass-Hintergrund (NSVisualEffectView).
final class RecordingHUD {

    // MARK: - Shared

    static let shared = RecordingHUD()
    private init() {}

    // MARK: - Constants

    private let size: CGFloat = 140

    // MARK: - Private State

    private var window:    NSWindow?
    private var pulseLayer: CALayer?

    // MARK: - Public API

    /// Zeigt das HUD animiert in der Bildschirmmitte an.
    func show() {
        DispatchQueue.main.async { [weak self] in
            self?.present()
        }
    }

    /// Blendet das HUD aus und stoppt die Pulsanimation.
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss()
        }
    }

    // MARK: - Present / Dismiss

    private func present() {
        if window == nil { window = makeWindow() }
        guard let window else { return }

        // Bildschirmmitte berechnen
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let sf = screen.frame
        let origin = NSPoint(
            x: sf.midX - size / 2,
            y: sf.midY - size / 2
        )
        window.setFrameOrigin(origin)

        if !window.isVisible {
            window.alphaValue = 0
            window.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.2
                window.animator().alphaValue = 1
            }
        }

        startPulse()
    }

    private func dismiss() {
        stopPulse()
        guard let window, window.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
        })
    }

    // MARK: - Window / View Construction

    private func makeWindow() -> NSWindow {
        let w = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size, height: size),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        w.level                = .floating
        w.isOpaque             = false
        w.backgroundColor      = .clear
        w.hasShadow            = true
        w.ignoresMouseEvents   = true
        w.collectionBehavior   = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Sehr transparenter Hintergrund — .underWindowBackground zeigt den
        // Desktop fast unverändert durch, nur minimale Tönung.
        let fx = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        fx.material      = .underWindowBackground
        fx.blendingMode  = .behindWindow
        fx.state         = .active
        fx.maskImage     = Self.circleMaskImage(diameter: size)
        w.contentView    = fx

        // Mikrofon-Symbol — labelColor passt zu hellem & dunklem Hintergrund
        let iconSize: CGFloat = 56
        let iconFrame = NSRect(
            x: (size - iconSize) / 2,
            y: (size - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        let iconView = NSImageView(frame: iconFrame)
        if let img = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Aufnahme läuft") {
            let config = NSImage.SymbolConfiguration(pointSize: 44, weight: .medium)
            iconView.image = img.withSymbolConfiguration(config)
        }
        iconView.contentTintColor = .labelColor
        iconView.imageScaling     = .scaleProportionallyUpOrDown
        fx.addSubview(iconView)

        // Puls-Ring-Layer (wird von startPulse animiert)
        let pulse = CALayer()
        pulse.frame       = CGRect(x: 0, y: 0, width: size, height: size)
        pulse.cornerRadius = size / 2
        pulse.borderColor = NSColor.labelColor.withAlphaComponent(0.5).cgColor
        pulse.borderWidth = 3
        pulse.opacity     = 0
        fx.layer?.insertSublayer(pulse, at: 0)
        pulseLayer = pulse

        return w
    }

    // MARK: - Puls-Animation

    private func startPulse() {
        guard let pulse = pulseLayer else { return }
        pulse.removeAllAnimations()

        // Scale: Ring wächst nach außen
        let scale        = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue  = 0.85
        scale.toValue    = 1.18

        // Opacity: Ring blendet aus
        let fade         = CABasicAnimation(keyPath: "opacity")
        fade.fromValue   = 0.7
        fade.toValue     = 0.0

        let group            = CAAnimationGroup()
        group.animations     = [scale, fade]
        group.duration       = 1.2
        group.repeatCount    = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)

        pulse.add(group, forKey: "recordingPulse")
    }

    private func stopPulse() {
        pulseLayer?.removeAllAnimations()
    }

    // MARK: - Helpers

    /// Kreisförmige Maske für NSVisualEffectView (verhindert milchige Ecken).
    private static func circleMaskImage(diameter: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: diameter, height: diameter), flipped: false) { rect in
            NSColor.black.set()
            NSBezierPath(ovalIn: rect).fill()
            return true
        }
        let inset = diameter / 2
        image.capInsets       = NSEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        image.resizingMode    = .stretch
        return image
    }
}
