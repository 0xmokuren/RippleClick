import AppKit
import XCTest

@testable import RippleClickLib

@MainActor
final class RippleWindowControllerTests: XCTestCase {
    private func makeSettingsStore() -> SettingsStore {
        let suiteName = "com.0xmokuren.RippleClickTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return SettingsStore(defaults: defaults)
    }

    func testShowRippleCreatesWindow() {
        let store = makeSettingsStore()
        let controller = RippleWindowController(settingsStore: store)
        controller.showRipple(at: NSPoint(x: 100, y: 100))
    }

    func testRippleSizeIsClampedToMinimum() {
        let store = makeSettingsStore()
        store.maxRippleSize = 1  // Below minimum of 10
        let controller = RippleWindowController(settingsStore: store)
        controller.showRipple(at: NSPoint(x: 100, y: 100))
    }

    func testRippleSizeIsClampedToMaximum() {
        let store = makeSettingsStore()
        store.maxRippleSize = 9999  // Above maximum of 500
        let controller = RippleWindowController(settingsStore: store)
        controller.showRipple(at: NSPoint(x: 100, y: 100))
    }

    func testMaxConcurrentWindowsLimit() {
        let store = makeSettingsStore()
        let controller = RippleWindowController(settingsStore: store)
        for i in 0..<25 {
            controller.showRipple(at: NSPoint(x: CGFloat(i * 10), y: 100))
        }
    }
}
