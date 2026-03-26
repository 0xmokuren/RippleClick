import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var clickMonitor: ClickMonitor?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let settingsStore = SettingsStore.shared
        statusBarController = StatusBarController(settingsStore: settingsStore)
        clickMonitor = ClickMonitor(settingsStore: settingsStore)
        clickMonitor?.start()

        statusBarController?.onToggle = { [weak self] enabled in
            self?.clickMonitor?.isEnabled = enabled
        }
    }
}
