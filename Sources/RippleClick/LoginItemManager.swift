import ServiceManagement

enum LoginItemManager {
    static func setEnabled(_ enabled: Bool) {
        guard Bundle.main.bundleIdentifier != nil else { return }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("LoginItemManager: \(enabled ? "register" : "unregister") failed: \(error)")
        }
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
