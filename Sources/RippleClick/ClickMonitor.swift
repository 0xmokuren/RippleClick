import AppKit
import ApplicationServices

@MainActor
final class ClickMonitor {
    private let settingsStore: SettingsStore
    private let rippleWindowController: RippleWindowController
    private var monitor: Any?

    var isEnabled: Bool {
        get { settingsStore.isEnabled }
        set { settingsStore.isEnabled = newValue }
    }

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.rippleWindowController = RippleWindowController(settingsStore: settingsStore)
    }

    func start() {
        requestAccessibilityIfNeeded()

        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleClick(event)
            }
        }
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handleClick(_ event: NSEvent) {
        guard settingsStore.isEnabled else { return }
        let location = NSEvent.mouseLocation

        if event.type == .rightMouseDown {
            guard settingsStore.rightClickEnabled else { return }
            rippleWindowController.showRipple(at: location, clickType: .rightClick)
        } else if event.clickCount >= 2 {
            guard settingsStore.doubleClickEnabled else { return }
            rippleWindowController.showRipple(at: location, clickType: .doubleClick)
        } else {
            rippleWindowController.showRipple(at: location, clickType: .leftClick)
        }

        if settingsStore.soundEnabled {
            SoundPlayer.shared.playSound(
                type: settingsStore.soundType, volume: settingsStore.soundVolume)
        }
    }

    private func requestAccessibilityIfNeeded() {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
        if !trusted {
            print("Accessibility permission not granted. Global click monitoring may not work.")
        }
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
