import AppKit
import XCTest

@testable import RippleClickLib

@MainActor
final class SettingsStoreTests: XCTestCase {
    private func makeStore() -> SettingsStore {
        let suiteName = "com.0xmokuren.RippleClickTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return SettingsStore(defaults: defaults)
    }

    func testIsEnabledDefaultsToTrue() {
        let store = makeStore()
        XCTAssertTrue(store.isEnabled)
    }

    func testIsEnabledPersistsValue() {
        let store = makeStore()
        store.isEnabled = false
        XCTAssertFalse(store.isEnabled)
        store.isEnabled = true
        XCTAssertTrue(store.isEnabled)
    }

    func testRippleColorDefaultsToCyan() {
        let store = makeStore()
        let color = store.rippleColor.usingColorSpace(.sRGB)!
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red, 0, accuracy: 0.01)
        XCTAssertEqual(green, 1, accuracy: 0.01)
        XCTAssertEqual(blue, 1, accuracy: 0.01)
        XCTAssertEqual(alpha, 1, accuracy: 0.01)
    }

    func testRippleColorPersistsCustomColor() {
        let store = makeStore()
        store.rippleColor = NSColor(red: 1, green: 0, blue: 0, alpha: 1)
        let color = store.rippleColor.usingColorSpace(.sRGB)!
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red, 1, accuracy: 0.01)
        XCTAssertEqual(green, 0, accuracy: 0.01)
        XCTAssertEqual(blue, 0, accuracy: 0.01)
    }

    func testRippleColorPostsNotification() {
        let store = makeStore()
        let expectation = expectation(forNotification: .rippleColorChanged, object: nil)
        store.rippleColor = NSColor.red
        wait(for: [expectation], timeout: 1)
    }

    func testMaxRippleSizeDefaultsTo100() {
        let store = makeStore()
        XCTAssertEqual(store.maxRippleSize, 100)
    }

    func testMaxRippleSizePersistsValue() {
        let store = makeStore()
        store.maxRippleSize = 200
        XCTAssertEqual(store.maxRippleSize, 200)
        store.maxRippleSize = 30
        XCTAssertEqual(store.maxRippleSize, 30)
    }

    func testSizeStepsHasFiveLevels() {
        let steps = SettingsWindowController.sizeSteps
        XCTAssertEqual(steps.count, 5)
        XCTAssertEqual(steps.first, 30)
        XCTAssertEqual(steps.last, 200)
        XCTAssertEqual(steps[2], 100)
    }
}
