import AppKit
import XCTest

@testable import RippleClickLib

/// 実際に NSPopover を表示した状態でタブを切り替え、ウィンドウ高と view 高が
/// 食い違わないか（上部に空き帯ができないか）を確認する。
@MainActor
final class LivePopoverTests: XCTestCase {
    func testPopoverResizesConsistentlyOnTabSwitch() throws {
        guard let defaults = UserDefaults(suiteName: "live.popover.suite") else { return }
        for key in defaults.dictionaryRepresentation().keys { defaults.removeObject(forKey: key) }
        let store = SettingsStore(defaults: defaults)
        let viewController = SettingsViewController(settingsStore: store)

        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 300, height: 200),
            styleMask: [.titled], backing: .buffered, defer: false)
        let anchor = NSView(frame: NSRect(x: 20, y: 20, width: 40, height: 20))
        window.contentView?.addSubview(anchor)
        window.orderFront(nil)

        let popover = NSPopover()
        popover.behavior = .applicationDefined
        popover.animates = false
        popover.contentViewController = viewController
        popover.delegate = viewController
        viewController.popover = popover
        viewController.prepareForDisplay()
        popover.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .maxY)
        try XCTSkipUnless(popover.isShown, "popover を表示できない環境")

        var deltas: [String: CGFloat] = [:]
        for tab in [SettingsTab.ripple, .color, .sound, .general, .ripple, .sound] {
            viewController.selectTab(tab)
            let expected = viewController.popoverViewHeight()
            // popover のリサイズ反映は非同期。負荷で遅れても落ちないよう収束待ちにする。
            let deadline = Date().addingTimeInterval(2)
            while Date() < deadline,
                abs(viewController.view.frame.height - expected) > 1
            {
                RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            }
            // 追加のランループを回さずに検査する。frame 変更と同期して
            // 再配置されていなければ、ここで1フレーム分のズレを捕まえられる。
            let viewHeight = viewController.view.frame.height
            let windowHeight = viewController.view.window?.frame.height ?? 0
            XCTAssertEqual(viewHeight, expected, accuracy: 1, "\(tab): view 高")
            XCTAssertEqual(
                viewController.headerView?.frame.maxY ?? 0, viewHeight, accuracy: 1,
                "\(tab): ヘッダーが上端にない")
            deltas["\(tab)"] = windowHeight - viewHeight
        }
        // ウィンドウ高 - view 高（枠と矢印の分）はタブによらず一定であるべき。
        // 一定でなければウィンドウだけ前のタブの高さに取り残されている。
        let values = Array(Set(deltas.values.map { ($0 * 10).rounded() / 10 }))
        XCTAssertEqual(values.count, 1, "ウィンドウと view の高さ差が一定でない: \(deltas)")
    }
}
