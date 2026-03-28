import AppKit

@MainActor
final class RippleWindowController {
    static let maxConcurrentWindows = 10

    private let settingsStore: SettingsStore
    private var activeWindows: [NSWindow] = []
    private var windowPool: [NSWindow] = []

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func showRipple(at screenPoint: NSPoint) {
        if activeWindows.count >= Self.maxConcurrentWindows {
            let oldest = activeWindows.removeFirst()
            recycleWindow(oldest)
        }

        let size = max(10, min(settingsStore.maxRippleSize, 500))
        let windowRect = NSRect(
            x: screenPoint.x - size / 2,
            y: screenPoint.y - size / 2,
            width: size,
            height: size
        )

        let window = acquireWindow(frame: windowRect, size: size)
        activeWindows.append(window)

        window.orderFrontRegardless()
        (window.contentView as? RippleView)?.startAnimation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self, weak window] in
            guard let window = window else { return }
            self?.activeWindows.removeAll { $0 === window }
            self?.recycleWindow(window)
        }
    }

    private func acquireWindow(frame: NSRect, size: CGFloat) -> NSWindow {
        if let window = windowPool.popLast() {
            window.setFrame(frame, display: false)
            if let rippleView = window.contentView as? RippleView {
                rippleView.frame = NSRect(x: 0, y: 0, width: size, height: size)
                rippleView.reset(color: settingsStore.rippleColor, maxSize: size)
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
            color: settingsStore.rippleColor,
            maxSize: size
        )
        window.contentView = rippleView

        return window
    }

    private func recycleWindow(_ window: NSWindow) {
        window.orderOut(nil)
        if windowPool.count < Self.maxConcurrentWindows {
            windowPool.append(window)
        }
    }
}
