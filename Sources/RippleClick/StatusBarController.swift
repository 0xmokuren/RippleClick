import AppKit

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let settingsStore: SettingsStore
    private var settingsWindowController: SettingsWindowController?
    private var toggleMenuItem: NSMenuItem?

    var onToggle: ((Bool) -> Void)?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        updateIcon()
        setupMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleColorChanged),
            name: .rippleColorChanged,
            object: nil
        )
    }

    func updateIcon() {
        guard let button = statusItem.button else { return }
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let ringRect = rect.insetBy(dx: 1.5, dy: 1.5)
            let ringPath = NSBezierPath(ovalIn: ringRect)
            NSColor.labelColor.setStroke()
            ringPath.lineWidth = 1.5
            ringPath.stroke()

            let dotRadius: CGFloat = 4
            let center = NSPoint(x: rect.midX, y: rect.midY)
            let dotRect = NSRect(
                x: center.x - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
            let dotPath = NSBezierPath(ovalIn: dotRect)
            if self.settingsStore.isEnabled {
                self.settingsStore.rippleColor.setFill()
            } else {
                NSColor.tertiaryLabelColor.setFill()
            }
            dotPath.fill()

            return true
        }
        image.isTemplate = false
        button.image = image
    }

    @objc private func handleColorChanged() {
        updateIcon()
    }

    private func setupMenu() {
        let menu = NSMenu()

        toggleMenuItem = NSMenuItem(
            title: localized("menu.toggle"),
            action: #selector(toggleEffect),
            keyEquivalent: ""
        )
        toggleMenuItem?.target = self
        toggleMenuItem?.state = settingsStore.isEnabled ? .on : .off
        if let item = toggleMenuItem { menu.addItem(item) }

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: localized("menu.settings"),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(
            title: localized("menu.about"),
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(
            title: localized("menu.quit"),
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleEffect() {
        let newState = !settingsStore.isEnabled
        settingsStore.isEnabled = newState
        toggleMenuItem?.state = newState ? .on : .off
        updateIcon()
        onToggle?(newState)
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(settingsStore: settingsStore)
        }
        settingsWindowController?.showWindow()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
