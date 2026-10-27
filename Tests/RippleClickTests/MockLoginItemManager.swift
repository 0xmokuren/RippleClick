@testable import RippleClickLib

/// All test stores must explicitly inject this fake instead of reaching SMAppService.
@MainActor
final class MockLoginItemManager: LoginItemManaging {
    var isEnabled = false
    var succeeds = true
    private(set) var requestedValues: [Bool] = []

    func setEnabled(_ enabled: Bool) -> Bool {
        requestedValues.append(enabled)
        if succeeds { isEnabled = enabled }
        return succeeds
    }
}
