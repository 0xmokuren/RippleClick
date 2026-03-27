import AppKit
import XCTest

@testable import RippleClickLib

@MainActor
final class LocalizationTests: XCTestCase {
    func testLocalizedReturnsValueForKnownKey() {
        let result = localized("menu.quit")
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, "menu.quit", "Known key should resolve to a translated string")
    }

    func testLocalizedReturnsKeyForUnknownKey() {
        let unknownKey = "this.key.does.not.exist"
        XCTAssertEqual(localized(unknownKey), unknownKey)
    }

    func testAllColorPresetKeysAreLocalized() {
        let colorKeys = SettingsWindowController.colorPresets.map(\.key)
        for key in colorKeys {
            let result = localized(key)
            XCTAssertNotEqual(result, key, "Color key '\(key)' should be localized")
        }
    }
}
