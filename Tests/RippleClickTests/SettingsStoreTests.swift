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

    func testAnimationDurationDefaultsTo0_5() {
        let store = makeStore()
        XCTAssertEqual(store.animationDuration, 0.5, accuracy: 0.001)
    }

    func testAnimationDurationPersistsValue() {
        let store = makeStore()
        store.animationDuration = 0.25
        XCTAssertEqual(store.animationDuration, 0.25, accuracy: 0.001)
        store.animationDuration = 1.0
        XCTAssertEqual(store.animationDuration, 1.0, accuracy: 0.001)
    }

    func testSpeedStepsHasFiveLevels() {
        let steps = SettingsWindowController.speedSteps
        XCTAssertEqual(steps.count, 5)
        XCTAssertEqual(steps.first, 0.25)
        XCTAssertEqual(steps.last, 1.0)
        XCTAssertEqual(steps[2], 0.5)
    }

    func testRippleOpacityDefaultsTo0_6() {
        let store = makeStore()
        XCTAssertEqual(store.rippleOpacity, 0.6, accuracy: 0.001)
    }

    func testRippleOpacityPersistsValue() {
        let store = makeStore()
        store.rippleOpacity = 0.4
        XCTAssertEqual(store.rippleOpacity, 0.4, accuracy: 0.001)
        store.rippleOpacity = 0.8
        XCTAssertEqual(store.rippleOpacity, 0.8, accuracy: 0.001)
    }

    func testOpacityStepsHasFiveLevels() {
        let steps = SettingsWindowController.opacitySteps
        XCTAssertEqual(steps.count, 5)
        XCTAssertEqual(steps.first, 0.15)
        XCTAssertEqual(steps.last, 1.0)
    }

    func testMaxRippleSizeClampsNegativeValue() {
        let store = makeStore()
        store.maxRippleSize = -10
        XCTAssertEqual(store.maxRippleSize, 10)
    }

    func testMaxRippleSizeClampsExcessiveValue() {
        let store = makeStore()
        store.maxRippleSize = 9999
        XCTAssertEqual(store.maxRippleSize, 500)
    }

    func testAnimationDurationClampsToRange() {
        let store = makeStore()
        store.animationDuration = 0.01
        XCTAssertEqual(store.animationDuration, 0.1, accuracy: 0.001)
        store.animationDuration = 99
        XCTAssertEqual(store.animationDuration, 2.0, accuracy: 0.001)
    }

    func testRippleOpacityClampsToRange() {
        let store = makeStore()
        store.rippleOpacity = 0.0
        XCTAssertEqual(store.rippleOpacity, 0.1, accuracy: 0.001)
        store.rippleOpacity = 5.0
        XCTAssertEqual(store.rippleOpacity, 1.0, accuracy: 0.001)
    }

    func testAppearanceAwareColorDefaultsToFalse() {
        let store = makeStore()
        XCTAssertFalse(store.appearanceAwareColor)
    }

    func testAppearanceAwareColorPersistsValue() {
        let store = makeStore()
        store.appearanceAwareColor = true
        XCTAssertTrue(store.appearanceAwareColor)
    }

    func testLightModeColorDefaultsToCyan() {
        let store = makeStore()
        let color = store.lightModeColor.usingColorSpace(.sRGB)!
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        XCTAssertEqual(red, 0, accuracy: 0.01)
        XCTAssertEqual(green, 1, accuracy: 0.01)
        XCTAssertEqual(blue, 1, accuracy: 0.01)
    }

    func testDarkModeColorDefaultsToCyan() {
        let store = makeStore()
        let color = store.darkModeColor.usingColorSpace(.sRGB)!
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        XCTAssertEqual(red, 0, accuracy: 0.01)
        XCTAssertEqual(green, 1, accuracy: 0.01)
        XCTAssertEqual(blue, 1, accuracy: 0.01)
    }

    func testLightModeColorPersistsValue() {
        let store = makeStore()
        store.lightModeColor = NSColor(red: 1, green: 0, blue: 0, alpha: 1)
        let color = store.lightModeColor.usingColorSpace(.sRGB)!
        var red: CGFloat = 0
        color.getRed(&red, green: nil, blue: nil, alpha: nil)
        XCTAssertEqual(red, 1, accuracy: 0.01)
    }

    func testDarkModeColorPersistsValue() {
        let store = makeStore()
        store.darkModeColor = NSColor(red: 0, green: 0, blue: 1, alpha: 1)
        let color = store.darkModeColor.usingColorSpace(.sRGB)!
        var blue: CGFloat = 0
        color.getRed(nil, green: nil, blue: &blue, alpha: nil)
        XCTAssertEqual(blue, 1, accuracy: 0.01)
    }

    func testSizeStepsHasFiveLevels() {
        let steps = SettingsWindowController.sizeSteps
        XCTAssertEqual(steps.count, 5)
        XCTAssertEqual(steps.first, 30)
        XCTAssertEqual(steps.last, 200)
        XCTAssertEqual(steps[2], 100)
    }

    // MARK: - Right-click settings

    func testRightClickEnabledDefaultsToTrue() {
        let store = makeStore()
        XCTAssertTrue(store.rightClickEnabled)
    }

    func testRightClickEnabledPersistsValue() {
        let store = makeStore()
        store.rightClickEnabled = false
        XCTAssertFalse(store.rightClickEnabled)
    }

    func testRightClickColorDefaultsToCyan() {
        let store = makeStore()
        let color = store.rightClickColor.usingColorSpace(.sRGB)!
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        XCTAssertEqual(red, 0, accuracy: 0.01)
        XCTAssertEqual(green, 1, accuracy: 0.01)
        XCTAssertEqual(blue, 1, accuracy: 0.01)
    }

    func testRightClickColorPersistsValue() {
        let store = makeStore()
        store.rightClickColor = NSColor(red: 1, green: 0, blue: 0, alpha: 1)
        let color = store.rightClickColor.usingColorSpace(.sRGB)!
        var red: CGFloat = 0
        color.getRed(&red, green: nil, blue: nil, alpha: nil)
        XCTAssertEqual(red, 1, accuracy: 0.01)
    }

    // MARK: - Double-click settings

    func testDoubleClickEnabledDefaultsToTrue() {
        let store = makeStore()
        XCTAssertTrue(store.doubleClickEnabled)
    }

    func testDoubleClickEnabledPersistsValue() {
        let store = makeStore()
        store.doubleClickEnabled = false
        XCTAssertFalse(store.doubleClickEnabled)
    }

    func testDoubleClickColorDefaultsToCyan() {
        let store = makeStore()
        let color = store.doubleClickColor.usingColorSpace(.sRGB)!
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        XCTAssertEqual(red, 0, accuracy: 0.01)
        XCTAssertEqual(green, 1, accuracy: 0.01)
        XCTAssertEqual(blue, 1, accuracy: 0.01)
    }

    func testDoubleClickColorPersistsValue() {
        let store = makeStore()
        store.doubleClickColor = NSColor(red: 0, green: 0, blue: 1, alpha: 1)
        let color = store.doubleClickColor.usingColorSpace(.sRGB)!
        var blue: CGFloat = 0
        color.getRed(nil, green: nil, blue: &blue, alpha: nil)
        XCTAssertEqual(blue, 1, accuracy: 0.01)
    }

    // MARK: - rippleColor(for:)

    func testRippleColorForClickTypeReturnsCorrectColor() {
        let store = makeStore()
        store.rippleColor = NSColor(red: 1, green: 0, blue: 0, alpha: 1)
        store.rightClickColor = NSColor(red: 0, green: 1, blue: 0, alpha: 1)
        store.doubleClickColor = NSColor(red: 0, green: 0, blue: 1, alpha: 1)

        let leftColor = store.rippleColor(for: .leftClick).usingColorSpace(.sRGB)!
        var leftRed: CGFloat = 0
        leftColor.getRed(&leftRed, green: nil, blue: nil, alpha: nil)
        XCTAssertEqual(leftRed, 1, accuracy: 0.01)

        let rightColor = store.rippleColor(for: .rightClick).usingColorSpace(.sRGB)!
        var rightGreen: CGFloat = 0
        rightColor.getRed(nil, green: &rightGreen, blue: nil, alpha: nil)
        XCTAssertEqual(rightGreen, 1, accuracy: 0.01)

        let doubleColor = store.rippleColor(for: .doubleClick).usingColorSpace(.sRGB)!
        var doubleBlue: CGFloat = 0
        doubleColor.getRed(nil, green: nil, blue: &doubleBlue, alpha: nil)
        XCTAssertEqual(doubleBlue, 1, accuracy: 0.01)
    }

    // MARK: - Sound settings

    func testSoundEnabledDefaultsToFalse() {
        let store = makeStore()
        XCTAssertFalse(store.soundEnabled)
    }

    func testSoundEnabledPersistsValue() {
        let store = makeStore()
        store.soundEnabled = true
        XCTAssertTrue(store.soundEnabled)
    }

    func testSoundTypeDefaultsToWaterDrop() {
        let store = makeStore()
        XCTAssertEqual(store.soundType, .waterDrop)
    }

    func testSoundTypePersistsValue() {
        let store = makeStore()
        store.soundType = .bubble
        XCTAssertEqual(store.soundType, .bubble)
    }

    func testSoundTypeHandlesInvalidRawValue() {
        let suiteName = "com.0xmokuren.RippleClickTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("nonexistentSound", forKey: "soundType")
        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.soundType, .waterDrop)
    }

    func testSoundVolumeDefaultsToHalf() {
        let store = makeStore()
        XCTAssertEqual(store.soundVolume, 0.5, accuracy: 0.001)
    }

    func testSoundVolumePersistsValue() {
        let store = makeStore()
        store.soundVolume = 0.75
        XCTAssertEqual(store.soundVolume, 0.75, accuracy: 0.001)
    }

    func testSoundVolumeClampsToRange() {
        let store = makeStore()
        store.soundVolume = -1.0
        XCTAssertEqual(store.soundVolume, 0.0, accuracy: 0.001)
        store.soundVolume = 5.0
        XCTAssertEqual(store.soundVolume, 1.0, accuracy: 0.001)
    }
}
