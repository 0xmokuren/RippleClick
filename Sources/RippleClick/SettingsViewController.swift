import AppKit

@MainActor
final class FlippedClipView: NSClipView {
    override var isFlipped: Bool { true }
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
    static let baseHeight: CGFloat = 632
    static let appearanceExtraHeight: CGFloat = 100
    static let clickTypeToggleHeight: CGFloat = 28
    // ヘッダー(常時表示帯)の高さ。下に出る効果トグル行(=32)とは別概念。
    static let headerHeight: CGFloat = 36
    // buildSections から取り除いた効果トグル行が元々占めていた高さ。
    // documentHeight でドキュメント高から差し引く。headerHeight(36)とは独立。
    static let effectToggleRowHeight: CGFloat = 32
    static let margin: CGFloat = 20
    static let colorButtonSize: CGFloat = 28
    static let colorButtonSpacing: CGFloat = 8

    let settingsStore: SettingsStore
    weak var popover: NSPopover?
    var onEffectToggle: ((Bool) -> Void)?
    var scrollView: NSScrollView?
    var sectionsView: NSView?
    var headerView: NSView?
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
    var selectedClickType: ClickType = .leftClick
    var clickTypeEnabledToggle: NSSwitch?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let height = popoverViewHeight()
        let effectView = NSVisualEffectView(
            frame: NSRect(x: 0, y: 0, width: Self.contentWidth, height: height))
        effectView.material = .popover
        effectView.state = .active
        effectView.blendingMode = .behindWindow

        let header = NSView(
            frame: NSRect(
                x: 0, y: height - Self.headerHeight,
                width: Self.contentWidth, height: Self.headerHeight))
        header.autoresizingMask = [.width, .minYMargin]

        let scroll = NSScrollView(
            frame: NSRect(
                x: 0, y: 0,
                width: Self.contentWidth, height: height - Self.headerHeight))
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay
        scroll.autoresizingMask = [.width, .height]

        let clip = FlippedClipView()
        clip.drawsBackground = false
        scroll.contentView = clip

        let sections = NSView(
            frame: NSRect(
                x: 0, y: 0, width: Self.contentWidth, height: documentHeight()))
        sections.autoresizesSubviews = false
        scroll.documentView = sections

        effectView.addSubview(scroll)
        effectView.addSubview(header)
        view = effectView
        headerView = header
        scrollView = scroll
        sectionsView = sections
        preferredContentSize = view.frame.size
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildHeader()
        buildSections()
    }

    func contentHeight() -> CGFloat {
        return Self.baseHeight
            + (settingsStore.appearanceAwareColor ? Self.appearanceExtraHeight : 0)
            + (selectedClickType != .leftClick ? Self.clickTypeToggleHeight : 0)
    }

    func popoverViewHeight() -> CGFloat {
        // ヘッダー(36) + documentView がちょうど収まる高さ。
        // documentHeight は effectToggleRowHeight(32) 基準なので header(36) との差4px を
        // 足し込むことで scroll 領域とドキュメント高が一致し、スクロールが発生しない。
        // 画面に収まらない極小ディスプレイ時のみクランプする。
        let target = documentHeight() + Self.headerHeight
        let available = (NSScreen.main?.visibleFrame.height ?? 800) - 8
        return min(target, max(320, available))
    }

    func documentHeight() -> CGFloat {
        return contentHeight() - Self.effectToggleRowHeight
    }

    func buildHeader() {
        guard let header = headerView else { return }
        let labelHeight: CGFloat = 20
        let labelY = (Self.headerHeight - labelHeight) / 2
        let label = NSTextField(
            frame: NSRect(
                x: Self.margin, y: labelY, width: 230, height: labelHeight))
        label.stringValue = localized("settings.effectEnabled")
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 13)
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

        let separator = NSBox(
            frame: NSRect(x: 0, y: 0, width: Self.contentWidth, height: 1))
        separator.boxType = .separator
        separator.autoresizingMask = [.width]
        header.addSubview(separator)
    }

    func buildSections() {
        guard let sections = sectionsView else { return }
        let isAppearanceAware = settingsStore.appearanceAwareColor
        var yOffset = sections.frame.height - 32
        yOffset = addColorSection(to: sections, yOffset: yOffset, appearanceAware: isAppearanceAware)
        yOffset = addSizeSection(to: sections, yOffset: yOffset)
        yOffset = addSpeedSection(to: sections, yOffset: yOffset)
        yOffset = addOpacitySection(to: sections, yOffset: yOffset)
        yOffset = addSoundSection(to: sections, yOffset: yOffset)
        yOffset = addGeneralSection(to: sections, yOffset: yOffset)
        addBottomButtons(to: sections, yOffset: yOffset)
    }

    /// NSPopover 非表示時専用（StatusBarController の show 直前からのみ呼ぶ）。
    /// 表示中(rebuildContent 等)からは絶対に呼ばない。view/header/scroll の frame と
    /// preferredContentSize をアトミックに揃え、表示中の非同期リサイズを完全に排除する。
    func applyPopoverGeometry(viewHeight: CGFloat) {
        view.frame.size = NSSize(width: Self.contentWidth, height: viewHeight)
        headerView?.frame = NSRect(
            x: 0, y: viewHeight - Self.headerHeight,
            width: Self.contentWidth, height: Self.headerHeight)
        scrollView?.frame = NSRect(
            x: 0, y: 0,
            width: Self.contentWidth, height: viewHeight - Self.headerHeight)
        sectionsView?.frame.size = NSSize(width: Self.contentWidth, height: documentHeight())
        preferredContentSize = NSSize(width: Self.contentWidth, height: viewHeight)
        // 開くたびにスクロール位置を上端へリセット（前回のスクロールを引き継がない）。
        scrollToTop()
    }

    func rebuildContent() {
        guard let sections = sectionsView else { return }
        sections.subviews.forEach { $0.removeFromSuperview() }
        colorButtons = []
        lightColorButtons = []
        darkColorButtons = []
        clickTypeEnabledToggle = nil
        soundToggle = nil
        soundTypePopUp = nil
        soundPreviewButton = nil
        volumeSlider = nil
        // 表示中はサイズを一切変えない（view/header/scroll frame と preferredContentSize は
        // 触らない）。変えるのは documentView 高のみ。view 高は show 直前に確定済み。
        sections.frame.size = NSSize(width: Self.contentWidth, height: documentHeight())
        buildSections()
        scrollToTop()
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

    @objc func effectToggleChanged(_ sender: NSSwitch) {
        let newState = (sender.state == .on)
        settingsStore.isEnabled = newState
        onEffectToggle?(newState)
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
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
        sizeSlider?.integerValue = 2

        settingsStore.animationDuration = Self.speedSteps[2]
        speedSlider?.integerValue = 2

        settingsStore.rippleOpacity = Self.opacitySteps[2]
        opacitySlider?.integerValue = 2

        settingsStore.launchAtLogin = false
        loginToggle?.state = .off

        settingsStore.soundEnabled = false
        soundToggle?.state = .off
        soundPreviewButton?.isEnabled = false
        settingsStore.soundType = .softClick
        soundTypePopUp?.selectItem(at: SoundType.allCases.firstIndex(of: .softClick) ?? 4)
        settingsStore.soundVolume = Self.volumeSteps[2]
        volumeSlider?.integerValue = 2

        selectedClickType = .leftClick
        rebuildContent()
    }

    @objc func soundToggleChanged(_ sender: NSSwitch) {
        settingsStore.soundEnabled = (sender.state == .on)
        soundPreviewButton?.isEnabled = (sender.state == .on)
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
