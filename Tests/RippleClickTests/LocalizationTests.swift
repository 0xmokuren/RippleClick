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

    func testAllLanguagesHaveSameKeys() {
        let allStrings = allLocalizationStrings
        guard let englishKeys = allStrings["en"]?.keys else {
            XCTFail("English localization missing")
            return
        }
        let expectedKeys = Set(englishKeys)

        for (language, translations) in allStrings {
            let actualKeys = Set(translations.keys)
            let missing = expectedKeys.subtracting(actualKeys)
            let extra = actualKeys.subtracting(expectedKeys)

            XCTAssertTrue(
                missing.isEmpty,
                "Language '\(language)' missing keys: \(missing.sorted())"
            )
            XCTAssertTrue(
                extra.isEmpty,
                "Language '\(language)' has extra keys: \(extra.sorted())"
            )
        }
    }

    func testAllValuesAreNonEmpty() {
        for (language, translations) in allLocalizationStrings {
            for (key, value) in translations {
                XCTAssertFalse(
                    value.isEmpty,
                    "Language '\(language)' has empty value for key '\(key)'"
                )
            }
        }
    }
}
