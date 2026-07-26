import AppKit
import XCTest

@testable import RippleClickLib

@MainActor
final class ClickMonitorTests: XCTestCase {
    private func makeSettingsStore() -> SettingsStore {
        let suiteName = "com.0xmokuren.RippleClickTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return SettingsStore(defaults: defaults)
    }

    private func makeEvent(type: NSEvent.EventType, clickCount: Int) -> NSEvent {
        let event = NSEvent.mouseEvent(
            with: type,
            location: NSPoint(x: 100, y: 100),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: clickCount,
            pressure: 1
        )
        return event!
    }

    func testLeftClickShowsRipple() {
        let monitor = ClickMonitor(settingsStore: makeSettingsStore())
        monitor.handleClick(makeEvent(type: .leftMouseDown, clickCount: 1))
        XCTAssertEqual(monitor.rippleWindowController.activeWindows.count, 1)
    }

    func testDisabledEffectShowsNoRipple() {
        let store = makeSettingsStore()
        store.isEnabled = false
        let monitor = ClickMonitor(settingsStore: store)
        monitor.handleClick(makeEvent(type: .leftMouseDown, clickCount: 1))
        XCTAssertEqual(monitor.rippleWindowController.activeWindows.count, 0)
    }

    func testRightClickRespectsItsOwnFlag() {
        let store = makeSettingsStore()
        store.rightClickEnabled = false
        let monitor = ClickMonitor(settingsStore: store)
        monitor.handleClick(makeEvent(type: .rightMouseDown, clickCount: 1))
        XCTAssertEqual(monitor.rippleWindowController.activeWindows.count, 0)
    }

    func testDoubleClickRespectsItsOwnFlag() {
        let store = makeSettingsStore()
        store.doubleClickEnabled = false
        let monitor = ClickMonitor(settingsStore: store)
        monitor.handleClick(makeEvent(type: .leftMouseDown, clickCount: 2))
        XCTAssertEqual(monitor.rippleWindowController.activeWindows.count, 0)
    }

    /// グローバル監視だけでは自アプリがアクティブな間のクリックを拾えず、設定ポップオーバーを
    /// 開いたまま見え方を試せない。ローカル監視も張られることを担保する。
    func testStartInstallsBothGlobalAndLocalMonitors() {
        let monitor = ClickMonitor(settingsStore: makeSettingsStore())
        monitor.start()
        XCTAssertNotNil(monitor.globalMonitor)
        XCTAssertNotNil(monitor.localMonitor)

        monitor.stop()
        XCTAssertNil(monitor.globalMonitor)
        XCTAssertNil(monitor.localMonitor)
    }
}
