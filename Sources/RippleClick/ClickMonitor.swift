import AppKit
import ApplicationServices

@MainActor
final class ClickMonitor {
    private let settingsStore: SettingsStore
    let rippleWindowController: RippleWindowController
    private(set) var globalMonitor: Any?
    private(set) var localMonitor: Any?

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

        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleClick(event)
            }
        }

        // グローバル監視は自アプリがアクティブな間はイベントを受け取らないため、
        // 設定ポップオーバーを開いている最中だけ波紋が出なくなる。ローカル監視を併用して、
        // 設定を触りながらその場で見え方を確認できるようにする。
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleClick(event)
            }
            return event
        }
    }

    func stop() {
        for monitor in [globalMonitor, localMonitor].compactMap({ $0 }) {
            NSEvent.removeMonitor(monitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    func handleClick(_ event: NSEvent) {
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
        for monitor in [globalMonitor, localMonitor].compactMap({ $0 }) {
            NSEvent.removeMonitor(monitor)
        }
    }
}
