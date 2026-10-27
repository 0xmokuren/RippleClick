import ServiceManagement

@MainActor
protocol LoginItemManaging {
    func setEnabled(_ enabled: Bool) -> Bool
    var isEnabled: Bool { get }
}

struct LoginItemManager: LoginItemManaging {
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
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

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
