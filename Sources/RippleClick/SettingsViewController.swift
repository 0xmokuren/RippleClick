import AppKit

@MainActor
final class FlippedClipView: NSClipView {
    override var isFlipped: Bool { true }
}

/// 設定ポップオーバーのルートビュー。
/// NSPopover 主導のリサイズは frame だけ先に変わり `viewDidLayout` は次のパスまで来ないため、
/// その1フレームだけヘッダーが旧位置に残る。frame 変更と同期して再配置するために hook する。
@MainActor
final class SettingsContainerView: NSVisualEffectView {
    var onFrameSizeChange: (() -> Void)?

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        onFrameSizeChange?()
    }
}

@MainActor
final class SettingsViewController: NSViewController, NSPopoverDelegate {
    public static let sizeSteps: [CGFloat] = [30, 70, 100, 150, 200]
    public static let speedSteps: [CFTimeInterval] = [0.25, 0.35, 0.5, 0.7, 1.0]
    public static let opacitySteps: [CGFloat] = [0.15, 0.35, 0.6, 0.8, 1.0]
    public static let volumeSteps: [Float] = [0.1, 0.25, 0.5, 0.75, 1.0]

    public static let colorPresets: [(key: String, color: NSColor)] = [
        ("color.cyan", NSColor(red: 0, green: 1, blue: 1, alpha: 1)),
        ("color.blue", NSColor(red: 0.2, green: 0.5, blue: 1, alpha: 1)),
        ("color.navy", NSColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 1)),
        ("color.purple", NSColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 1)),
        ("color.pink", NSColor(red: 1, green: 0.4, blue: 0.6, alpha: 1)),
        ("color.red", NSColor(red: 1, green: 0.25, blue: 0.25, alpha: 1)),
        ("color.orange", NSColor(red: 1, green: 0.6, blue: 0.2, alpha: 1)),
        ("color.yellow", NSColor(red: 1, green: 0.85, blue: 0.2, alpha: 1)),
        ("color.lime", NSColor(red: 0.5, green: 0.9, blue: 0.2, alpha: 1)),
        ("color.green", NSColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1)),
        ("color.teal", NSColor(red: 0.2, green: 0.8, blue: 0.7, alpha: 1)),
        ("color.white", NSColor(red: 1, green: 1, blue: 1, alpha: 1)),
    ]

    static let contentWidth: CGFloat = 380
    // 常時表示のクローム。ヘッダー(効果 ON/OFF)とタブバーはスクロールしない。
    static let headerHeight: CGFloat = 36
    static let tabBarHeight: CGFloat = 40
    static let contentTopPadding: CGFloat = 18
    static let contentBottomPadding: CGFloat = 20
    /// 同一タブ内でセクションを並べるときの縦の間隔。
    static let sectionGap: CGFloat = 28
    static let minViewHeight: CGFloat = 200
    static let margin: CGFloat = 20
    static let rowHeight: CGFloat = 20
    static let colorButtonSize: CGFloat = 28
    static let colorButtonSpacing: CGFloat = 8

    let settingsStore: SettingsStore
    weak var popover: NSPopover?
    var onEffectToggle: ((Bool) -> Void)?
    var onPopoverClose: (() -> Void)?
    var scrollView: NSScrollView?
    var sectionsView: NSView?
    var headerView: NSView?
    var tabBarView: NSView?
    var tabControl: NSSegmentedControl?
    var effectToggle: NSSwitch?
    var sizeSlider: NSSlider?
    var speedSlider: NSSlider?
    var opacitySlider: NSSlider?
    var loginToggle: NSSwitch?
    var appearanceToggle: NSSwitch?
    var colorButtons: [NSButton] = []
    var lightColorButtons: [NSButton] = []
    var darkColorButtons: [NSButton] = []
    var soundToggle: NSSwitch?
    var soundTypePopUp: NSPopUpButton?
    var soundPreviewButton: NSButton?
    var volumeSlider: NSSlider?
    var selectedTab: SettingsTab = .ripple
    var selectedClickType: ClickType = .leftClick
    var clickTypeEnabledToggle: NSSwitch?

    /// buildSections が実際に積んだ高さ。ポップオーバーの高さはこれから逆算する。
    private var measuredContentHeight: CGFloat = 0

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let effectView = SettingsContainerView(
            frame: NSRect(
                x: 0, y: 0, width: Self.contentWidth, height: Self.minViewHeight))
        effectView.material = .popover
        effectView.state = .active
        effectView.blendingMode = .behindWindow
        effectView.onFrameSizeChange = { [weak self] in
            self?.layoutChrome()
        }

        // クロームは幅を確定させてから中身を組む。幅0の親に追加すると autoresizing の
        // 比例計算が崩れ、セグメントコントロールなどの幅が壊れる。
        let header = NSView(
            frame: NSRect(
                x: 0, y: Self.minViewHeight - Self.headerHeight,
                width: Self.contentWidth, height: Self.headerHeight))
        header.autoresizingMask = [.width, .minYMargin]

        let tabBar = NSView(
            frame: NSRect(
                x: 0, y: Self.minViewHeight - Self.chromeHeight,
                width: Self.contentWidth, height: Self.tabBarHeight))
        tabBar.autoresizingMask = [.width, .minYMargin]

        let scroll = NSScrollView(
            frame: NSRect(
                x: 0, y: 0, width: Self.contentWidth,
                height: Self.minViewHeight - Self.chromeHeight))
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        scroll.autoresizingMask = [.width, .height]

        let clip = FlippedClipView()
        clip.drawsBackground = false
        scroll.contentView = clip

        let sections = NSView(
            frame: NSRect(x: 0, y: 0, width: Self.contentWidth, height: Self.minViewHeight))
        sections.autoresizesSubviews = false
        scroll.documentView = sections

        effectView.addSubview(scroll)
        effectView.addSubview(tabBar)
        effectView.addSubview(header)
        view = effectView
        headerView = header
        tabBarView = tabBar
        scrollView = scroll
        sectionsView = sections
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildHeader()
        buildTabBar()
        rebuildContent()
    }

    // MARK: - Geometry

    static var chromeHeight: CGFloat { headerHeight + tabBarHeight }

    /// 選択中タブの実測高さにクロームを足したポップオーバーの高さ。
    /// 画面に収まらない極小ディスプレイ時のみクランプし、その場合だけスクロールが生じる。
    func popoverViewHeight() -> CGFloat {
        let target = documentHeight() + Self.chromeHeight
        let available = (NSScreen.main?.visibleFrame.height ?? 800) - 8
        return min(max(target, Self.minViewHeight), max(Self.minViewHeight, available))
    }

    func documentHeight() -> CGFloat {
        return max(measuredContentHeight, Self.minViewHeight - Self.chromeHeight)
    }

    /// 非表示時のサイズ確定用。表示中に呼ぶと NSPopover 側のウィンドウ高と食い違うので
    /// 呼んではいけない（表示中は popover.contentSize 経由でリサイズする）。
    func applyGeometry(viewHeight: CGFloat) {
        view.frame.size = NSSize(width: Self.contentWidth, height: viewHeight)
        preferredContentSize = view.frame.size
        layoutChrome()
        scrollToTop()
    }

    /// ヘッダー・タブバー・スクロール領域を view の実寸から配置する。
    /// NSPopover 主導のリサイズでは `SettingsContainerView.setFrameSize` から同期的に、
    /// それ以外のレイアウトパスでは `viewDidLayout` からここに来る。
    /// `isViewLoaded` を見るのは、loadView 中の frame 変更で loadView に再帰しないため。
    func layoutChrome() {
        guard isViewLoaded else { return }
        let width = view.frame.width
        let height = view.frame.height
        headerView?.frame = NSRect(
            x: 0, y: height - Self.headerHeight, width: width, height: Self.headerHeight)
        tabBarView?.frame = NSRect(
            x: 0, y: height - Self.chromeHeight, width: width, height: Self.tabBarHeight)
        scrollView?.frame = NSRect(
            x: 0, y: 0, width: width, height: max(0, height - Self.chromeHeight))
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        layoutChrome()
    }

    /// StatusBarController が show する直前に呼ぶ。トグル状態を実際の設定に合わせ、
    /// 選択中タブの内容とサイズを確定させる。
    func prepareForDisplay() {
        syncEffectToggle()
        rebuildContent()
    }

    // MARK: - Content

    func buildHeader() {
        guard let header = headerView else { return }
        let labelY = (Self.headerHeight - Self.rowHeight) / 2
        let label = NSTextField(
            frame: NSRect(x: Self.margin, y: labelY, width: 230, height: Self.rowHeight))
        label.stringValue = localized("settings.effectEnabled")
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        header.addSubview(label)

        let toggle = NSSwitch()
        toggle.controlSize = .small
        toggle.sizeToFit()
        let toggleY = max(0, (Self.headerHeight - toggle.frame.height) / 2)
        toggle.frame.origin = NSPoint(
            x: Self.contentWidth - Self.margin - toggle.frame.width, y: toggleY)
        toggle.state = settingsStore.isEnabled ? .on : .off
        toggle.target = self
        toggle.action = #selector(effectToggleChanged(_:))
        self.effectToggle = toggle
        header.addSubview(toggle)

        let separator = makeSeparator(width: Self.contentWidth, yPosition: 0)
        separator.autoresizingMask = [.width]
        header.addSubview(separator)
    }

    func buildTabBar() {
        guard let tabBar = tabBarView else { return }
        let control = NSSegmentedControl(
            labels: SettingsTab.allCases.map { localized($0.titleKey) },
            trackingMode: .selectOne,
            target: self,
            action: #selector(tabChanged(_:))
        )
        control.selectedSegment = selectedTab.rawValue
        // 4等分にしないとラベル幅に応じた固有幅のままになり、右端のタブが切れる。
        control.segmentDistribution = .fillEqually
        let controlHeight: CGFloat = 24
        control.frame = NSRect(
            x: Self.margin, y: (Self.tabBarHeight - controlHeight) / 2,
            width: Self.contentWidth - Self.margin * 2, height: controlHeight)
        control.autoresizingMask = [.width]
        self.tabControl = control
        tabBar.addSubview(control)

        let separator = makeSeparator(width: Self.contentWidth, yPosition: 0)
        separator.autoresizingMask = [.width]
        tabBar.addSubview(separator)
    }

    /// 各タブの内容を y = 0 から下方向へ積む。総高さは積み終わってから実測するので、
    /// タブごとの高さを定数で持たない（設定項目を増やしても定数調整が不要）。
    func buildSections() {
        guard let sections = sectionsView else { return }
        var yOffset: CGFloat = 0
        switch selectedTab {
        case .ripple:
            yOffset = addSizeSection(to: sections, yOffset: yOffset)
            yOffset = addSpeedSection(to: sections, yOffset: yOffset - Self.sectionGap)
            yOffset = addOpacitySection(to: sections, yOffset: yOffset - Self.sectionGap)
        case .color:
            yOffset = addColorSection(
                to: sections, yOffset: yOffset,
                appearanceAware: settingsStore.appearanceAwareColor)
        case .sound:
            yOffset = addSoundSection(to: sections, yOffset: yOffset)
        case .general:
            yOffset = addGeneralSection(to: sections, yOffset: yOffset)
        }
        alignSectionsToTop(in: sections)
    }

    /// buildSections が置いたサブビューの占有範囲を実測し、上下パディングを加えた高さの
    /// documentView に上詰めで収める。
    private func alignSectionsToTop(in sections: NSView) {
        guard let maxTop = sections.subviews.map(\.frame.maxY).max(),
            let minBottom = sections.subviews.map(\.frame.minY).min()
        else {
            measuredContentHeight = 0
            sections.frame.size = NSSize(width: Self.contentWidth, height: 0)
            return
        }
        let height =
            (maxTop - minBottom) + Self.contentTopPadding + Self.contentBottomPadding
        let shift = height - Self.contentTopPadding - maxTop
        for subview in sections.subviews {
            subview.frame.origin.y += shift
        }
        measuredContentHeight = height
        sections.frame.size = NSSize(width: Self.contentWidth, height: height)
    }

    func rebuildContent() {
        guard let sections = sectionsView else { return }
        for subview in sections.subviews {
            subview.removeFromSuperview()
        }
        clearControlReferences()
        buildSections()

        // タブ切替や外観トグルで高さが変わるため、表示中でもリサイズする。
        let height = popoverViewHeight()
        guard let popover = popover, popover.isShown else {
            applyGeometry(viewHeight: height)
            return
        }
        // 表示中は view.frame を先に書き換えてはいけない。NSPopover は contentSize を
        // view の実寸から見ているため、先に縮めると代入が同値扱いで無視され、
        // ウィンドウだけ前のタブの高さに取り残される。ウィンドウと view の
        // リサイズは popover に任せ、こちらは配置のみ viewDidLayout で追従する。
        popover.contentSize = NSSize(width: Self.contentWidth, height: height)
        preferredContentSize = NSSize(width: Self.contentWidth, height: height)
        scrollToTop()
    }

    private func clearControlReferences() {
        colorButtons = []
        lightColorButtons = []
        darkColorButtons = []
        clickTypeEnabledToggle = nil
        appearanceToggle = nil
        sizeSlider = nil
        speedSlider = nil
        opacitySlider = nil
        soundToggle = nil
        soundTypePopUp = nil
        soundPreviewButton = nil
        volumeSlider = nil
        loginToggle = nil
    }

    func scrollToTop() {
        // 目的地は常に .zero 定数（documentView 非flipped + clip flipped 前提）。
        // documentView frame 変更後のレイアウト確定は非同期なので、同期パスで layout を
        // 強制し、なお次ランループでも再適用して確実化する。
        guard let scroll = scrollView else { return }
        scroll.documentView?.layoutSubtreeIfNeeded()
        scroll.contentView.scroll(to: .zero)
        scroll.reflectScrolledClipView(scroll.contentView)
        DispatchQueue.main.async { [weak self] in
            guard let scroll = self?.scrollView else { return }
            scroll.contentView.scroll(to: .zero)
            scroll.reflectScrolledClipView(scroll.contentView)
        }
    }

    @objc func popoverDidShow(_ notification: Notification) {
        scrollToTop()
    }

    @objc func popoverDidClose(_ notification: Notification) {
        onPopoverClose?()
    }

    // MARK: - Click type color helpers

    func currentSelectedColor() -> NSColor {
        switch selectedClickType {
        case .leftClick: return settingsStore.rippleColor
        case .rightClick: return settingsStore.rightClickColor
        case .doubleClick: return settingsStore.doubleClickColor
        }
    }

    func currentLightColor() -> NSColor {
        switch selectedClickType {
        case .leftClick: return settingsStore.lightModeColor
        case .rightClick: return settingsStore.rightClickLightColor
        case .doubleClick: return settingsStore.doubleClickLightColor
        }
    }

    func currentDarkColor() -> NSColor {
        switch selectedClickType {
        case .leftClick: return settingsStore.darkModeColor
        case .rightClick: return settingsStore.rightClickDarkColor
        case .doubleClick: return settingsStore.doubleClickDarkColor
        }
    }

    func nearestIndex<T: BinaryFloatingPoint>(for value: T, in steps: [T]) -> Int {
        var bestIndex = 0
        var bestDiff = T.greatestFiniteMagnitude
        for (index, step) in steps.enumerated() {
            let diff = abs(value - step)
            if diff < bestDiff {
                bestDiff = diff
                bestIndex = index
            }
        }
        return bestIndex
    }

    func colorsMatch(_ colorA: NSColor, _ colorB: NSColor) -> Bool {
        guard let srgbA = colorA.usingColorSpace(.sRGB),
            let srgbB = colorB.usingColorSpace(.sRGB)
        else {
            return false
        }
        var red1: CGFloat = 0
        var green1: CGFloat = 0
        var blue1: CGFloat = 0
        var alpha1: CGFloat = 0
        var red2: CGFloat = 0
        var green2: CGFloat = 0
        var blue2: CGFloat = 0
        var alpha2: CGFloat = 0
        srgbA.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
        srgbB.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)
        return abs(red1 - red2) < 0.05 && abs(green1 - green2) < 0.05
            && abs(blue1 - blue2) < 0.05
    }

    // MARK: - Actions

    func syncEffectToggle() {
        effectToggle?.state = settingsStore.isEnabled ? .on : .off
    }

    func selectTab(_ tab: SettingsTab) {
        selectedTab = tab
        tabControl?.selectedSegment = tab.rawValue
        rebuildContent()
    }

    @objc func tabChanged(_ sender: NSSegmentedControl) {
        guard let tab = SettingsTab(rawValue: sender.selectedSegment) else { return }
        selectTab(tab)
    }

    @objc func effectToggleChanged(_ sender: NSSwitch) {
        let newState = (sender.state == .on)
        settingsStore.isEnabled = newState
        onEffectToggle?(newState)
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    @objc func showAboutPanel() {
        // About パネルは通常ウィンドウレベルなので、フローティングなポップオーバーを開いたままだと
        // その背面に隠れて何も起きていないように見える。先に閉じ、アクティブ化してから出す。
        popover?.performClose(nil)
        activateApp()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    private func activateApp() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// transient ポップオーバーはモーダルにキーウィンドウを奪われると閉じてしまうため、
    /// モーダルの間だけ自動クローズを止めて、設定画面を開いたまま確認できるようにする。
    private func runModalKeepingPopover(_ alert: NSAlert) -> NSApplication.ModalResponse {
        let previousBehavior = popover?.behavior
        popover?.behavior = .applicationDefined
        defer {
            if let previousBehavior {
                popover?.behavior = previousBehavior
            }
        }
        activateApp()
        return alert.runModal()
    }

    @objc func appearanceToggleChanged(_ sender: NSSwitch) {
        settingsStore.appearanceAwareColor = (sender.state == .on)
        rebuildContent()
    }

    @objc func clickTypeSegmentChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0: selectedClickType = .leftClick
        case 1: selectedClickType = .rightClick
        case 2: selectedClickType = .doubleClick
        default: selectedClickType = .leftClick
        }
        rebuildContent()
    }

    @objc func clickTypeEnabledChanged(_ sender: NSSwitch) {
        let enabled = (sender.state == .on)
        switch selectedClickType {
        case .rightClick: settingsStore.rightClickEnabled = enabled
        case .doubleClick: settingsStore.doubleClickEnabled = enabled
        case .leftClick: break
        }
    }

    @objc func colorSelected(_ sender: NSButton) {
        let preset = Self.colorPresets[sender.tag]
        switch selectedClickType {
        case .leftClick: settingsStore.rippleColor = preset.color
        case .rightClick: settingsStore.rightClickColor = preset.color
        case .doubleClick: settingsStore.doubleClickColor = preset.color
        }
        for button in colorButtons {
            updateColorButtonBorder(button, selected: button.tag == sender.tag)
        }
    }

    @objc func lightColorSelected(_ sender: NSButton) {
        let preset = Self.colorPresets[sender.tag]
        switch selectedClickType {
        case .leftClick: settingsStore.lightModeColor = preset.color
        case .rightClick: settingsStore.rightClickLightColor = preset.color
        case .doubleClick: settingsStore.doubleClickLightColor = preset.color
        }
        for button in lightColorButtons {
            updateColorButtonBorder(button, selected: button.tag == sender.tag)
        }
    }

    @objc func darkColorSelected(_ sender: NSButton) {
        let preset = Self.colorPresets[sender.tag]
        switch selectedClickType {
        case .leftClick: settingsStore.darkModeColor = preset.color
        case .rightClick: settingsStore.rightClickDarkColor = preset.color
        case .doubleClick: settingsStore.doubleClickDarkColor = preset.color
        }
        for button in darkColorButtons {
            updateColorButtonBorder(button, selected: button.tag == sender.tag)
        }
    }

    @objc func sizeChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.sizeSteps.count - 1)
        settingsStore.maxRippleSize = Self.sizeSteps[index]
    }

    @objc func speedChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.speedSteps.count - 1)
        settingsStore.animationDuration = Self.speedSteps[index]
    }

    @objc func opacityChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.opacitySteps.count - 1)
        settingsStore.rippleOpacity = Self.opacitySteps[index]
    }

    @objc func resetToDefaults() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = localized("settings.reset.confirm.title")
        alert.informativeText = localized("settings.reset.confirm.message")
        alert.addButton(withTitle: localized("settings.reset"))
        alert.addButton(withTitle: localized("common.cancel"))
        // 誤操作でいきなり全設定が飛ばないよう、破壊的な方を既定ボタンにしない。
        alert.buttons.first?.keyEquivalent = ""
        alert.buttons.last?.keyEquivalent = "\r"
        guard runModalKeepingPopover(alert) == .alertFirstButtonReturn else { return }
        applyDefaults()
    }

    func applyDefaults() {
        settingsStore.appearanceAwareColor = false
        settingsStore.rippleColor = Self.colorPresets[0].color
        settingsStore.lightModeColor = Self.colorPresets[0].color
        settingsStore.darkModeColor = Self.colorPresets[0].color

        settingsStore.rightClickEnabled = true
        settingsStore.rightClickColor = Self.colorPresets[0].color
        settingsStore.rightClickLightColor = Self.colorPresets[0].color
        settingsStore.rightClickDarkColor = Self.colorPresets[0].color

        settingsStore.doubleClickEnabled = true
        settingsStore.doubleClickColor = Self.colorPresets[0].color
        settingsStore.doubleClickLightColor = Self.colorPresets[0].color
        settingsStore.doubleClickDarkColor = Self.colorPresets[0].color

        settingsStore.maxRippleSize = Self.sizeSteps[2]
        settingsStore.animationDuration = Self.speedSteps[2]
        settingsStore.rippleOpacity = Self.opacitySteps[2]

        settingsStore.launchAtLogin = false
        settingsStore.soundEnabled = false
        settingsStore.soundType = .softClick
        settingsStore.soundVolume = Self.volumeSteps[2]

        selectedClickType = .leftClick
        rebuildContent()
    }

    @objc func soundToggleChanged(_ sender: NSSwitch) {
        settingsStore.soundEnabled = (sender.state == .on)
        updateSoundControlsEnabled()
    }

    /// クリック音 OFF のときは種類・音量・試聴を操作対象から外す。
    func updateSoundControlsEnabled() {
        let enabled = settingsStore.soundEnabled
        soundTypePopUp?.isEnabled = enabled
        volumeSlider?.isEnabled = enabled
        soundPreviewButton?.isEnabled = enabled
    }

    @objc func soundPreviewPressed(_ sender: NSButton) {
        SoundPlayer.shared.playSound(
            type: settingsStore.soundType, volume: settingsStore.soundVolume)
    }

    @objc func soundTypeChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        if index >= 0, index < SoundType.allCases.count {
            settingsStore.soundType = SoundType.allCases[index]
        }
        SoundPlayer.shared.playSound(
            type: settingsStore.soundType, volume: settingsStore.soundVolume)
    }

    @objc func volumeChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.volumeSteps.count - 1)
        settingsStore.soundVolume = Self.volumeSteps[index]
        SoundPlayer.shared.playSound(
            type: settingsStore.soundType, volume: settingsStore.soundVolume)
    }

    @objc func launchAtLoginChanged(_ sender: NSSwitch) {
        settingsStore.launchAtLogin = (sender.state == .on)
    }
}
