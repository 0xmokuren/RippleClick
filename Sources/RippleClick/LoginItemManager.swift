import ServiceManagement

enum LoginItemManager {
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard Bundle.main.bundleIdentifier != nil else { return false }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            print("LoginItemManager: \(enabled ? "register" : "unregister") failed: \(error)")
            return false
        }
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
