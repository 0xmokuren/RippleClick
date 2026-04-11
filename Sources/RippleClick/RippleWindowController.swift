import AppKit

@MainActor
final class RippleWindowController {
    static let maxConcurrentWindows = 10

    private let settingsStore: SettingsStore
    private(set) var activeWindows: [NSWindow] = []
    private(set) var windowPool: [NSWindow] = []

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func showRipple(at screenPoint: NSPoint, clickType: ClickType = .leftClick) {
        if activeWindows.count >= Self.maxConcurrentWindows {
            let oldest = activeWindows.removeFirst()
            recycleWindow(oldest)
        }

        let sizeMultiplier: CGFloat = (clickType == .doubleClick) ? 1.2 : 1.0
        let size = max(10, min(settingsStore.maxRippleSize * sizeMultiplier, 600))
        let windowRect = NSRect(
            x: screenPoint.x - size / 2,
            y: screenPoint.y - size / 2,
            width: size,
            height: size
        )

        let color = settingsStore.rippleColor(for: clickType)
        let ringCount: Int = (clickType == .rightClick) ? 2 : 1
        let strokeMultiplier: CGFloat = (clickType == .doubleClick) ? 2.0 : 1.0

        let duration = settingsStore.animationDuration
        let opacity = settingsStore.rippleOpacity
        let window = acquireWindow(
            frame: windowRect, size: size, duration: duration, opacity: opacity,
            color: color, ringCount: ringCount, strokeMultiplier: strokeMultiplier)
        activeWindows.append(window)

        window.orderFrontRegardless()
        (window.contentView as? RippleView)?.startAnimation()

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) { [weak self, weak window] in
            guard let window = window else { return }
            self?.activeWindows.removeAll { $0 === window }
            self?.recycleWindow(window)
        }
    }

    private func acquireWindow(
        frame: NSRect,
        size: CGFloat,
        duration: CFTimeInterval,
        opacity: CGFloat,
        color: NSColor,
        ringCount: Int = 1,
        strokeMultiplier: CGFloat = 1.0
    ) -> NSWindow {
        if let window = windowPool.popLast() {
            window.setFrame(frame, display: false)
            if let rippleView = window.contentView as? RippleView {
                rippleView.frame = NSRect(x: 0, y: 0, width: size, height: size)
                rippleView.reset(
                    color: color, maxSize: size,
                    duration: duration, opacity: opacity,
                    ringCount: ringCount, strokeMultiplier: strokeMultiplier
                )
            }
            return window
        }

        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        let rippleView = RippleView(
            frame: NSRect(x: 0, y: 0, width: size, height: size),
            color: color,
            maxSize: size,
            duration: duration,
            opacity: opacity,
            ringCount: ringCount,
            strokeMultiplier: strokeMultiplier
        )
        window.contentView = rippleView

        return window
    }

    private func recycleWindow(_ window: NSWindow) {
        window.orderOut(nil)
        (window.contentView as? RippleView)?.clearLayers()
        if windowPool.count < Self.maxConcurrentWindows {
            windowPool.append(window)
        }
    }
}
