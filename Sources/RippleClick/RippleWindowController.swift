import AppKit

@MainActor
final class RippleWindowController {
    private static let maxConcurrentWindows = 20

    private let settingsStore: SettingsStore
    private var activeWindows: [NSWindow] = []

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func showRipple(at screenPoint: NSPoint) {
        if activeWindows.count >= Self.maxConcurrentWindows {
            let oldest = activeWindows.removeFirst()
            oldest.orderOut(nil)
        }

        let size = max(10, min(settingsStore.maxRippleSize, 500))
        let windowRect = NSRect(
            x: screenPoint.x - size / 2,
            y: screenPoint.y - size / 2,
            width: size,
            height: size
        )

        let window = NSWindow(
            contentRect: windowRect,
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

        activeWindows.append(window)

        let rippleView = RippleView(
            frame: NSRect(x: 0, y: 0, width: size, height: size),
            color: settingsStore.rippleColor,
            maxSize: size
        )

        window.contentView = rippleView
        window.orderFrontRegardless()
        rippleView.startAnimation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self, weak window] in
            guard let window = window else { return }
            window.orderOut(nil)
            self?.activeWindows.removeAll { $0 === window }
        }
    }
}
