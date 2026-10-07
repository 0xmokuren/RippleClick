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

    /// 入力監視の権限が無い間は CGEventTap を張れないため、設定ポップオーバー上でプレビューできるよう
    /// ローカル監視で代用し、権限も要求する。
    func testStartFallsBackToLocalMonitorWithoutListenAccess() {
        var requestCount = 0
        let access = ListenEventAccess(isGranted: { false }, request: { requestCount += 1 })
        let monitor = ClickMonitor(settingsStore: makeSettingsStore(), listenEventAccess: access)
        monitor.start()
        XCTAssertNil(monitor.eventTap)
        XCTAssertNotNil(monitor.localMonitor)
        XCTAssertEqual(requestCount, 1)

        monitor.stop()
        XCTAssertNil(monitor.eventTap)
        XCTAssertNil(monitor.localMonitor)
    }

    /// 権限がまだ無いと分かっている間は、ポーリングしても CGEventTap に切り替えずローカル監視を保つ。
    func testSwitchToEventTapKeepsLocalMonitorWhileAccessIsDenied() {
        let access = ListenEventAccess(isGranted: { false }, request: {})
        let monitor = ClickMonitor(settingsStore: makeSettingsStore(), listenEventAccess: access)
        monitor.start()
        monitor.switchToEventTapIfGranted()
        XCTAssertNil(monitor.eventTap)
        XCTAssertNotNil(monitor.localMonitor)
        monitor.stop()
    }

    func testRightClickShowsRippleViaCGEventPath() {
        let monitor = ClickMonitor(settingsStore: makeSettingsStore())
        monitor.handleClick(isRightClick: true, clickCount: 1)
        XCTAssertEqual(monitor.rippleWindowController.activeWindows.count, 1)
    }
}
