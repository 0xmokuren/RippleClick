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

    func testShowRippleAddsActiveWindow() {
        let store = makeSettingsStore()
        let controller = RippleWindowController(settingsStore: store)
        XCTAssertEqual(controller.activeWindows.count, 0)
        controller.showRipple(at: NSPoint(x: 100, y: 100))
        XCTAssertEqual(controller.activeWindows.count, 1)
    }

    func testShowRippleWindowHasRippleView() {
        let store = makeSettingsStore()
        let controller = RippleWindowController(settingsStore: store)
        controller.showRipple(at: NSPoint(x: 100, y: 100))
        XCTAssertTrue(controller.activeWindows.first?.contentView is RippleView)
    }

    func testRippleSizeIsClampedToMinimum() {
        let store = makeSettingsStore()
        store.maxRippleSize = 1  // Below minimum of 10
        let controller = RippleWindowController(settingsStore: store)
        controller.showRipple(at: NSPoint(x: 100, y: 100))
        let window = controller.activeWindows.first!
        XCTAssertGreaterThanOrEqual(window.frame.width, 10)
    }

    func testRippleSizeIsClampedToMaximum() {
        let store = makeSettingsStore()
        store.maxRippleSize = 9999  // Above maximum of 500
        let controller = RippleWindowController(settingsStore: store)
        controller.showRipple(at: NSPoint(x: 100, y: 100))
        let window = controller.activeWindows.first!
        XCTAssertLessThanOrEqual(window.frame.width, 500)
    }

    func testActiveWindowsDoNotExceedLimit() {
        let store = makeSettingsStore()
        let controller = RippleWindowController(settingsStore: store)
        let limit = RippleWindowController.maxConcurrentWindows

        for i in 0..<(limit + 5) {
            controller.showRipple(at: NSPoint(x: CGFloat(i * 10), y: 100))
        }

        XCTAssertEqual(controller.activeWindows.count, limit)
    }

    func testMultipleRipplesCreateDistinctWindows() {
        let store = makeSettingsStore()
        let controller = RippleWindowController(settingsStore: store)
        controller.showRipple(at: NSPoint(x: 100, y: 100))
        controller.showRipple(at: NSPoint(x: 200, y: 200))
        XCTAssertEqual(controller.activeWindows.count, 2)
        XCTAssertNotIdentical(controller.activeWindows[0], controller.activeWindows[1])
    }
}
