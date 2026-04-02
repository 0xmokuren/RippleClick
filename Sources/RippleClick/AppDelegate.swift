import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var clickMonitor: ClickMonitor?
    private var appearanceObservation: NSKeyValueObservation?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settingsStore = SettingsStore.shared
        statusBarController = StatusBarController(settingsStore: settingsStore)
        clickMonitor = ClickMonitor(settingsStore: settingsStore)
        clickMonitor?.start()

        statusBarController?.onToggle = { [weak self] enabled in
            self?.clickMonitor?.isEnabled = enabled
        }

        appearanceObservation = NSApp.observe(\.effectiveAppearance) { _, _ in
            DispatchQueue.main.async {
                if settingsStore.appearanceAwareColor {
                    NotificationCenter.default.post(name: .rippleColorChanged, object: nil)
                }
            }
        }
    }
}
