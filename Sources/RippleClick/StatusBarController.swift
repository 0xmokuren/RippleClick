import AppKit

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let settingsStore: SettingsStore
    private var settingsViewController: SettingsViewController?
    private var settingsPopover: NSPopover?
    private var contextMenu: NSMenu?
    private var toggleMenuItem: NSMenuItem?

    var onToggle: ((Bool) -> Void)?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        updateIcon()
        setupStatusButton()

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

    private func setupStatusButton() {
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

        contextMenu = menu

        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func toggleEffect() {
        let newState = !settingsStore.isEnabled
        settingsStore.isEnabled = newState
        handleEffectToggled(newState)
    }

    private func handleEffectToggled(_ enabled: Bool) {
        toggleMenuItem?.state = enabled ? .on : .off
        updateIcon()
        onToggle?(enabled)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick =
            event?.type == .rightMouseUp || (event?.modifierFlags.contains(.control) ?? false)
        if isRightClick {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func showContextMenu() {
        guard let menu = contextMenu else { return }
        toggleMenuItem?.state = settingsStore.isEnabled ? .on : .off
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func togglePopover() {
        if let popover = settingsPopover, popover.isShown {
            popover.performClose(nil)
            settingsPopover = nil
            return
        }

        if settingsViewController == nil {
            let viewController = SettingsViewController(settingsStore: settingsStore)
            viewController.onEffectToggle = { [weak self] enabled in
                self?.handleEffectToggled(enabled)
            }
            settingsViewController = viewController
        }

        let popover = NSPopover()
        popover.contentViewController = settingsViewController
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = settingsViewController
        settingsPopover = popover
        settingsViewController?.popover = popover
        settingsViewController?.syncEffectToggle()

        guard let button = statusItem.button else { return }
        if let viewController = settingsViewController {
            viewController.applyPopoverGeometry(viewHeight: viewController.popoverViewHeight())
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        activateApp()
    }

    private func activateApp() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func showAbout() {
        activateApp()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
