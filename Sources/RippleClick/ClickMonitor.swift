import AppKit
import CoreGraphics

/// 入力監視（Input Monitoring）権限の確認と要求をまとめたもの。
/// テストでは実際の TCC の状態に依存しないよう差し替えます。
struct ListenEventAccess {
    var isGranted: () -> Bool
    var request: () -> Void

    static let system = ListenEventAccess(
        isGranted: { CGPreflightListenEventAccess() },
        request: {
            _ = CGRequestListenEventAccess()
            // CGRequestListenEventAccess だけではダイアログが出ず、入力監視の一覧にも載らない環境があるため、
            // listen-only のタップを実際に作ろうとして要求を確実に届ける。作れても使わずにすぐ破棄する。
            if let probe = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: CGEventMask(1) << CGEventType.leftMouseDown.rawValue,
                callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
                userInfo: nil
            ) {
                CFMachPortInvalidate(probe)
            }
        }
    )
}

@MainActor
final class ClickMonitor {
    private let settingsStore: SettingsStore
    private let listenEventAccess: ListenEventAccess
    let rippleWindowController: RippleWindowController
    private(set) var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private(set) var localMonitor: Any?
    private var accessPollTimer: Timer?

    /// 権限が後から許可されたかを確認する間隔です。
    static let accessPollInterval: TimeInterval = 2

    var isEnabled: Bool {
        get { settingsStore.isEnabled }
        set { settingsStore.isEnabled = newValue }
    }

    init(settingsStore: SettingsStore, listenEventAccess: ListenEventAccess = .system) {
        self.settingsStore = settingsStore
        self.listenEventAccess = listenEventAccess
        self.rippleWindowController = RippleWindowController(settingsStore: settingsStore)
    }

    // App Sandbox 下ではアクセシビリティ権限が使えないため、NSEvent のグローバル監視ではなく
    // 入力監視権限で動く CGEventTap を使う。CGEventTap は自アプリ宛てのクリックも受け取るので、
    // 権限がある間はローカル監視を張らない（張ると波紋が二重に出る）。
    func start() {
        if listenEventAccess.isGranted() {
            installEventTap()
        }
        guard eventTap == nil else { return }

        // 権限が無い間も設定ポップオーバー上でプレビューできるよう、ローカル監視で代用します。
        listenEventAccess.request()
        installLocalMonitor()
        startPollingForAccess()
    }

    func stop() {
        accessPollTimer?.invalidate()
        accessPollTimer = nil
        removeEventTap()
        removeLocalMonitor()
    }

    func handleClick(_ event: NSEvent) {
        handleClick(isRightClick: event.type == .rightMouseDown, clickCount: event.clickCount)
    }

    func handleClick(isRightClick: Bool, clickCount: Int) {
        guard settingsStore.isEnabled else { return }
        let location = NSEvent.mouseLocation

        if isRightClick {
            guard settingsStore.rightClickEnabled else { return }
            rippleWindowController.showRipple(at: location, clickType: .rightClick)
        } else if clickCount >= 2 {
            guard settingsStore.doubleClickEnabled else { return }
            rippleWindowController.showRipple(at: location, clickType: .doubleClick)
        } else {
            rippleWindowController.showRipple(at: location, clickType: .leftClick)
        }

        if settingsStore.soundEnabled {
            SoundPlayer.shared.playSound(
                type: settingsStore.soundType, volume: settingsStore.soundVolume)
        }
    }

    // MARK: - CGEventTap

    private func installEventTap() {
        let mask =
            (CGEventMask(1) << CGEventType.leftMouseDown.rawValue)
            | (CGEventMask(1) << CGEventType.rightMouseDown.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: mask,
                callback: clickEventTapCallback,
                userInfo: userInfo
            )
        else {
            return
        }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
        eventTapSource = source
    }

    private func removeEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        eventTapSource = nil
    }

    /// 処理が遅れたりユーザー入力で止められたりするとタップが無効化されるため、有効に戻します。
    fileprivate func reenableEventTap() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    // MARK: - Fallback while Input Monitoring is not granted

    private func installLocalMonitor() {
        guard localMonitor == nil else { return }
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleClick(event)
            }
            return event
        }
    }

    private func removeLocalMonitor() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        localMonitor = nil
    }

    private func startPollingForAccess() {
        accessPollTimer?.invalidate()
        accessPollTimer = Timer.scheduledTimer(
            withTimeInterval: Self.accessPollInterval, repeats: true
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.switchToEventTapIfGranted()
            }
        }
    }

    func switchToEventTapIfGranted() {
        guard eventTap == nil, listenEventAccess.isGranted() else { return }
        installEventTap()
        guard eventTap != nil else { return }
        accessPollTimer?.invalidate()
        accessPollTimer = nil
        removeLocalMonitor()
    }

    deinit {
        accessPollTimer?.invalidate()
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// C の関数ポインタとして渡すため、値をキャプチャしないトップレベル関数にしています。
private func clickEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<ClickMonitor>.fromOpaque(userInfo).takeUnretainedValue()

    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        DispatchQueue.main.async {
            monitor.reenableEventTap()
        }
    case .leftMouseDown, .rightMouseDown:
        let isRightClick = type == .rightMouseDown
        let clickCount = Int(event.getIntegerValueField(.mouseEventClickState))
        DispatchQueue.main.async {
            monitor.handleClick(isRightClick: isRightClick, clickCount: clickCount)
        }
    default:
        break
    }
    return Unmanaged.passUnretained(event)
}
