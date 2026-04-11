import AppKit

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
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

    private static let windowWidth: CGFloat = 380
    private static let baseHeight: CGFloat = 600
    private static let appearanceExtraHeight: CGFloat = 100
    private static let clickTypeToggleHeight: CGFloat = 28
    private static let margin: CGFloat = 20
    private static let colorButtonSize: CGFloat = 28
    private static let colorButtonSpacing: CGFloat = 8

    private let settingsStore: SettingsStore
    private var window: NSWindow?
    private var sizeSlider: NSSlider?
    private var speedSlider: NSSlider?
    private var opacitySlider: NSSlider?
    private var loginToggle: NSSwitch?
    private var appearanceToggle: NSSwitch?
    private var colorButtons: [NSButton] = []
    private var lightColorButtons: [NSButton] = []
    private var darkColorButtons: [NSButton] = []
    private var soundToggle: NSSwitch?
    private var soundTypePopUp: NSPopUpButton?
    private var soundPreviewButton: NSButton?
    private var volumeSlider: NSSlider?
    private var selectedClickType: ClickType = .leftClick
    private var clickTypeEnabledToggle: NSSwitch?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        super.init()
    }

    func showWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        buildWindow()
    }

    private func buildWindow() {
        let isAppearanceAware = settingsStore.appearanceAwareColor
        let showClickTypeToggle = (selectedClickType != .leftClick)
        let windowHeight =
            Self.baseHeight + (isAppearanceAware ? Self.appearanceExtraHeight : 0)
            + (showClickTypeToggle ? Self.clickTypeToggleHeight : 0)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.windowWidth, height: windowHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = localized("settings.title")
        window.delegate = self
        window.center()
        window.isReleasedWhenClosed = false

        let contentView = NSView(
            frame: NSRect(x: 0, y: 0, width: Self.windowWidth, height: windowHeight)
        )
        window.contentView = contentView

        var yOffset = windowHeight - 32
        yOffset = addColorSection(to: contentView, yOffset: yOffset, appearanceAware: isAppearanceAware)
        yOffset = addSizeSection(to: contentView, yOffset: yOffset)
        yOffset = addSpeedSection(to: contentView, yOffset: yOffset)
        yOffset = addOpacitySection(to: contentView, yOffset: yOffset)
        yOffset = addSoundSection(to: contentView, yOffset: yOffset)
        yOffset = addGeneralSection(to: contentView, yOffset: yOffset)
        addResetButton(to: contentView, yOffset: yOffset)

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func rebuildWindow() {
        let oldFrame = window?.frame
        window?.close()
        window = nil
        colorButtons = []
        lightColorButtons = []
        darkColorButtons = []
        clickTypeEnabledToggle = nil
        soundToggle = nil
        soundTypePopUp = nil
        soundPreviewButton = nil
        volumeSlider = nil
        buildWindow()
        if let oldFrame = oldFrame, let window = window {
            // Keep top-left corner fixed (grow downward)
            let newY = oldFrame.maxY - window.frame.height
            window.setFrameOrigin(NSPoint(x: oldFrame.origin.x, y: newY))
        }
    }

    // MARK: - Section builders

    private func addColorSection(
        to contentView: NSView, yOffset: CGFloat, appearanceAware: Bool
    ) -> CGFloat {
        var currentY = yOffset
        let label = makeSectionLabel(
            localized("settings.color"), origin: NSPoint(x: Self.margin, y: currentY),
            symbolName: "paintpalette")
        contentView.addSubview(label)

        // Click type segmented control
        currentY -= 28
        let segmentedControl = NSSegmentedControl(
            labels: [
                localized("settings.clickType.left"),
                localized("settings.clickType.right"),
                localized("settings.clickType.double"),
            ],
            trackingMode: .selectOne,
            target: self,
            action: #selector(clickTypeSegmentChanged(_:))
        )
        let segmentIndex: Int
        switch selectedClickType {
        case .leftClick: segmentIndex = 0
        case .rightClick: segmentIndex = 1
        case .doubleClick: segmentIndex = 2
        }
        segmentedControl.selectedSegment = segmentIndex
        segmentedControl.frame = NSRect(
            x: Self.margin, y: currentY,
            width: Self.windowWidth - Self.margin * 2, height: 24)
        contentView.addSubview(segmentedControl)

        // Enable toggle for right/double click
        if selectedClickType != .leftClick {
            currentY -= 28
            let enabledLabel = NSTextField(
                frame: NSRect(x: Self.margin, y: currentY, width: 230, height: 20))
            enabledLabel.stringValue =
                selectedClickType == .rightClick
                ? localized("settings.clickType.rightEnabled")
                : localized("settings.clickType.doubleEnabled")
            enabledLabel.isEditable = false
            enabledLabel.isBezeled = false
            enabledLabel.drawsBackground = false
            enabledLabel.font = .systemFont(ofSize: 13)
            contentView.addSubview(enabledLabel)

            let toggle = NSSwitch()
            toggle.controlSize = .small
            toggle.sizeToFit()
            toggle.frame.origin = NSPoint(
                x: Self.windowWidth - Self.margin - toggle.frame.width, y: currentY)
            let isOn =
                selectedClickType == .rightClick
                ? settingsStore.rightClickEnabled : settingsStore.doubleClickEnabled
            toggle.state = isOn ? .on : .off
            toggle.target = self
            toggle.action = #selector(clickTypeEnabledChanged(_:))
            self.clickTypeEnabledToggle = toggle
            contentView.addSubview(toggle)
        }

        // Appearance toggle
        currentY -= 24
        let toggleLabel = NSTextField(
            frame: NSRect(x: Self.margin, y: currentY, width: 230, height: 20))
        toggleLabel.stringValue = localized("settings.color.appearance")
        toggleLabel.isEditable = false
        toggleLabel.isBezeled = false
        toggleLabel.drawsBackground = false
        toggleLabel.font = .systemFont(ofSize: 13)
        contentView.addSubview(toggleLabel)

        let toggle = NSSwitch()
        toggle.controlSize = .small
        toggle.sizeToFit()
        toggle.frame.origin = NSPoint(
            x: Self.windowWidth - Self.margin - toggle.frame.width, y: currentY)
        toggle.state = appearanceAware ? .on : .off
        toggle.target = self
        toggle.action = #selector(appearanceToggleChanged(_:))
        self.appearanceToggle = toggle
        contentView.addSubview(toggle)

        if appearanceAware {
            currentY = addAppearanceAwareColorPalette(to: contentView, yOffset: currentY)
        } else {
            currentY = addSingleColorPalette(to: contentView, yOffset: currentY)
        }
        return currentY
    }

    private func addSingleColorPalette(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset
        let selectedColor = currentSelectedColor()
        colorButtons = []
        for row in 0..<2 {
            currentY -= (Self.colorButtonSize + 4)
            for col in 0..<6 {
                let index = row * 6 + col
                let preset = Self.colorPresets[index]
                let xPos =
                    Self.margin + CGFloat(col) * (Self.colorButtonSize + Self.colorButtonSpacing)

                let button = makeColorButton(
                    frame: NSRect(
                        x: xPos, y: currentY,
                        width: Self.colorButtonSize, height: Self.colorButtonSize),
                    preset: preset,
                    index: index,
                    action: #selector(colorSelected(_:)),
                    selectedColor: selectedColor
                )
                colorButtons.append(button)
                contentView.addSubview(button)
            }
        }
        return currentY
    }

    private func addAppearanceAwareColorPalette(
        to contentView: NSView, yOffset: CGFloat
    ) -> CGFloat {
        var currentY = yOffset
        let lightColor = currentLightColor()
        let darkColor = currentDarkColor()

        currentY -= 24
        let lightLabel = makeSubLabel(
            localized("settings.color.light"),
            origin: NSPoint(x: Self.margin + 8, y: currentY))
        contentView.addSubview(lightLabel)

        lightColorButtons = []
        for row in 0..<2 {
            currentY -= (Self.colorButtonSize + 4)
            for col in 0..<6 {
                let index = row * 6 + col
                let preset = Self.colorPresets[index]
                let xPos =
                    Self.margin + CGFloat(col) * (Self.colorButtonSize + Self.colorButtonSpacing)

                let button = makeColorButton(
                    frame: NSRect(
                        x: xPos, y: currentY,
                        width: Self.colorButtonSize, height: Self.colorButtonSize),
                    preset: preset,
                    index: index,
                    action: #selector(lightColorSelected(_:)),
                    selectedColor: lightColor
                )
                lightColorButtons.append(button)
                contentView.addSubview(button)
            }
        }

        currentY -= 24
        let darkLabel = makeSubLabel(
            localized("settings.color.dark"),
            origin: NSPoint(x: Self.margin + 8, y: currentY))
        contentView.addSubview(darkLabel)

        darkColorButtons = []
        for row in 0..<2 {
            currentY -= (Self.colorButtonSize + 4)
            for col in 0..<6 {
                let index = row * 6 + col
                let preset = Self.colorPresets[index]
                let xPos =
                    Self.margin + CGFloat(col) * (Self.colorButtonSize + Self.colorButtonSpacing)

                let button = makeColorButton(
                    frame: NSRect(
                        x: xPos, y: currentY,
                        width: Self.colorButtonSize, height: Self.colorButtonSize),
                    preset: preset,
                    index: index,
                    action: #selector(darkColorSelected(_:)),
                    selectedColor: darkColor
                )
                darkColorButtons.append(button)
                contentView.addSubview(button)
            }
        }
        return currentY
    }

    // MARK: - Click type color helpers

    private func currentSelectedColor() -> NSColor {
        switch selectedClickType {
        case .leftClick: return settingsStore.rippleColor
        case .rightClick: return settingsStore.rightClickColor
        case .doubleClick: return settingsStore.doubleClickColor
        }
    }

    private func currentLightColor() -> NSColor {
        switch selectedClickType {
        case .leftClick: return settingsStore.lightModeColor
        case .rightClick: return settingsStore.rightClickLightColor
        case .doubleClick: return settingsStore.doubleClickLightColor
        }
    }

    private func currentDarkColor() -> NSColor {
        switch selectedClickType {
        case .leftClick: return settingsStore.darkModeColor
        case .rightClick: return settingsStore.rightClickDarkColor
        case .doubleClick: return settingsStore.doubleClickDarkColor
        }
    }

    private func addSizeSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset - 28
        let title = makeSectionLabel(
            localized("settings.size"), origin: NSPoint(x: Self.margin, y: currentY),
            symbolName: "arrow.up.left.and.arrow.down.right")
        contentView.addSubview(title)

        currentY -= 28
        let slider = NSSlider(frame: NSRect(x: Self.margin, y: currentY, width: 260, height: 24))
        slider.minValue = 0
        slider.maxValue = Double(Self.sizeSteps.count - 1)
        slider.integerValue = nearestIndex(for: settingsStore.maxRippleSize, in: Self.sizeSteps)
        slider.numberOfTickMarks = Self.sizeSteps.count
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action = #selector(sizeChanged(_:))
        self.sizeSlider = slider
        contentView.addSubview(slider)

        currentY -= 16
        addEdgeLabels(
            to: contentView, yPosition: currentY,
            minText: localized("settings.size.min"),
            maxText: localized("settings.size.max"), sliderWidth: 260
        )
        return currentY
    }

    private func addSpeedSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset - 28
        let title = makeSectionLabel(
            localized("settings.speed"), origin: NSPoint(x: Self.margin, y: currentY),
            symbolName: "hare")
        contentView.addSubview(title)

        currentY -= 28
        let slider = NSSlider(frame: NSRect(x: Self.margin, y: currentY, width: 260, height: 24))
        slider.minValue = 0
        slider.maxValue = Double(Self.speedSteps.count - 1)
        slider.integerValue = nearestIndex(
            for: settingsStore.animationDuration, in: Self.speedSteps)
        slider.numberOfTickMarks = Self.speedSteps.count
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action = #selector(speedChanged(_:))
        self.speedSlider = slider
        contentView.addSubview(slider)

        currentY -= 16
        addEdgeLabels(
            to: contentView, yPosition: currentY,
            minText: localized("settings.speed.min"),
            maxText: localized("settings.speed.max"), sliderWidth: 260
        )
        return currentY
    }

    private func addOpacitySection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset - 28
        let title = makeSectionLabel(
            localized("settings.opacity"), origin: NSPoint(x: Self.margin, y: currentY),
            symbolName: "circle.lefthalf.filled")
        contentView.addSubview(title)

        currentY -= 28
        let slider = NSSlider(frame: NSRect(x: Self.margin, y: currentY, width: 260, height: 24))
        slider.minValue = 0
        slider.maxValue = Double(Self.opacitySteps.count - 1)
        slider.integerValue = nearestIndex(
            for: settingsStore.rippleOpacity, in: Self.opacitySteps)
        slider.numberOfTickMarks = Self.opacitySteps.count
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action = #selector(opacityChanged(_:))
        self.opacitySlider = slider
        contentView.addSubview(slider)

        currentY -= 16
        addEdgeLabels(
            to: contentView, yPosition: currentY,
            minText: localized("settings.opacity.min"),
            maxText: localized("settings.opacity.max"), sliderWidth: 260
        )
        return currentY
    }

    private func addSoundSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset - 28
        let title = makeSectionLabel(
            localized("settings.sound"), origin: NSPoint(x: Self.margin, y: currentY),
            symbolName: "speaker.wave.2")
        contentView.addSubview(title)

        currentY -= 24
        let enabledLabel = NSTextField(
            frame: NSRect(x: Self.margin, y: currentY, width: 230, height: 20))
        enabledLabel.stringValue = localized("settings.sound.enabled")
        enabledLabel.isEditable = false
        enabledLabel.isBezeled = false
        enabledLabel.drawsBackground = false
        enabledLabel.font = .systemFont(ofSize: 13)
        contentView.addSubview(enabledLabel)

        let toggle = NSSwitch()
        toggle.controlSize = .small
        toggle.sizeToFit()
        toggle.frame.origin = NSPoint(
            x: Self.windowWidth - Self.margin - toggle.frame.width, y: currentY)
        toggle.state = settingsStore.soundEnabled ? .on : .off
        toggle.target = self
        toggle.action = #selector(soundToggleChanged(_:))
        self.soundToggle = toggle
        contentView.addSubview(toggle)

        currentY -= 28
        let typeLabel = NSTextField(
            frame: NSRect(x: Self.margin, y: currentY, width: 100, height: 20))
        typeLabel.stringValue = localized("settings.sound.type")
        typeLabel.isEditable = false
        typeLabel.isBezeled = false
        typeLabel.drawsBackground = false
        typeLabel.font = .systemFont(ofSize: 13)
        contentView.addSubview(typeLabel)

        let popUp = NSPopUpButton(
            frame: NSRect(
                x: Self.margin + 110, y: currentY - 2,
                width: Self.windowWidth - Self.margin * 2 - 110 - 34, height: 24),
            pullsDown: false)
        for soundType in SoundType.allCases {
            popUp.addItem(withTitle: localized("sound.type.\(soundType.rawValue)"))
        }
        let selectedIndex = SoundType.allCases.firstIndex(of: settingsStore.soundType) ?? 0
        popUp.selectItem(at: selectedIndex)
        popUp.target = self
        popUp.action = #selector(soundTypeChanged(_:))
        self.soundTypePopUp = popUp
        contentView.addSubview(popUp)

        let previewButton = NSButton(
            frame: NSRect(
                x: Self.margin + 110 + 196 + 4, y: currentY - 2,
                width: 30, height: 24))
        previewButton.image = NSImage(
            systemSymbolName: "play.circle",
            accessibilityDescription: localized("settings.sound.preview"))
        previewButton.bezelStyle = .accessoryBarAction
        previewButton.imagePosition = .imageOnly
        previewButton.target = self
        previewButton.action = #selector(soundPreviewPressed(_:))
        previewButton.isEnabled = settingsStore.soundEnabled
        self.soundPreviewButton = previewButton
        contentView.addSubview(previewButton)

        currentY -= 28
        let slider = NSSlider(
            frame: NSRect(x: Self.margin, y: currentY, width: 260, height: 24))
        slider.minValue = 0
        slider.maxValue = Double(Self.volumeSteps.count - 1)
        slider.integerValue = nearestIndex(
            for: settingsStore.soundVolume, in: Self.volumeSteps)
        slider.numberOfTickMarks = Self.volumeSteps.count
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action = #selector(volumeChanged(_:))
        self.volumeSlider = slider
        contentView.addSubview(slider)

        currentY -= 16
        addEdgeLabels(
            to: contentView, yPosition: currentY,
            minText: localized("settings.sound.volume.min"),
            maxText: localized("settings.sound.volume.max"), sliderWidth: 260)
        return currentY
    }

    private func addGeneralSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset - 28
        let label = makeSectionLabel(
            localized("settings.general"), origin: NSPoint(x: Self.margin, y: currentY),
            symbolName: "gearshape")
        contentView.addSubview(label)

        currentY -= 24
        let loginLabel = NSTextField(
            frame: NSRect(x: Self.margin, y: currentY, width: 230, height: 20))
        loginLabel.stringValue = localized("settings.launchAtLogin")
        loginLabel.isEditable = false
        loginLabel.isBezeled = false
        loginLabel.drawsBackground = false
        loginLabel.font = .systemFont(ofSize: 13)
        contentView.addSubview(loginLabel)

        let toggle = NSSwitch()
        toggle.controlSize = .small
        toggle.sizeToFit()
        toggle.frame.origin = NSPoint(x: Self.windowWidth - Self.margin - toggle.frame.width, y: currentY)
        toggle.state = settingsStore.launchAtLogin ? .on : .off
        toggle.target = self
        toggle.action = #selector(launchAtLoginChanged(_:))
        self.loginToggle = toggle
        contentView.addSubview(toggle)
        return currentY
    }

    private func addResetButton(to contentView: NSView, yOffset: CGFloat) {
        let currentY = yOffset - 36
        let resetButton = NSButton(
            title: localized("settings.reset"),
            target: self, action: #selector(resetToDefaults)
        )
        resetButton.bezelStyle = .rounded
        resetButton.sizeToFit()
        resetButton.frame.origin = NSPoint(
            x: Self.windowWidth - resetButton.frame.width - Self.margin,
            y: currentY
        )
        contentView.addSubview(resetButton)
    }

    // MARK: - UI helpers

    private func makeColorButton(
        frame: NSRect,
        preset: (key: String, color: NSColor),
        index: Int,
        action: Selector,
        selectedColor: NSColor
    ) -> NSButton {
        let button = NSButton(frame: frame)
        button.title = ""
        button.bezelStyle = .circular
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = Self.colorButtonSize / 2
        button.layer?.backgroundColor = preset.color.cgColor
        button.toolTip = localized(preset.key)
        button.tag = index
        button.target = self
        button.action = action
        updateColorButtonBorder(button, selected: colorsMatch(preset.color, selectedColor))
        return button
    }

    private func addEdgeLabels(
        to contentView: NSView, yPosition: CGFloat,
        minText: String, maxText: String, sliderWidth: CGFloat
    ) {
        let minLabel = NSTextField(
            frame: NSRect(x: Self.margin, y: yPosition, width: 60, height: 14))
        minLabel.stringValue = minText
        minLabel.isEditable = false
        minLabel.isBezeled = false
        minLabel.drawsBackground = false
        minLabel.alignment = .left
        minLabel.font = .systemFont(ofSize: 10)
        minLabel.textColor = .tertiaryLabelColor
        contentView.addSubview(minLabel)

        let maxLabel = NSTextField(
            frame: NSRect(
                x: Self.margin + sliderWidth - 60, y: yPosition, width: 60, height: 14)
        )
        maxLabel.stringValue = maxText
        maxLabel.isEditable = false
        maxLabel.isBezeled = false
        maxLabel.drawsBackground = false
        maxLabel.alignment = .right
        maxLabel.font = .systemFont(ofSize: 10)
        maxLabel.textColor = .tertiaryLabelColor
        contentView.addSubview(maxLabel)
    }

    private func nearestIndex<T: BinaryFloatingPoint>(for value: T, in steps: [T]) -> Int {
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

    private func makeSectionLabel(
        _ text: String, origin: NSPoint, symbolName: String? = nil
    ) -> NSView {
        let container = NSView(frame: NSRect(x: origin.x, y: origin.y, width: 280, height: 18))

        var textX: CGFloat = 0
        if let symbolName = symbolName,
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: text)
        {
            let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 16, height: 16))
            imageView.image = image
            imageView.contentTintColor = .secondaryLabelColor
            container.addSubview(imageView)
            textX = 20
        }

        let label = NSTextField(
            frame: NSRect(x: textX, y: 0, width: 280 - textX, height: 18))
        label.stringValue = text
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        container.addSubview(label)

        return container
    }

    private func makeSubLabel(_ text: String, origin: NSPoint) -> NSTextField {
        let label = NSTextField(
            frame: NSRect(x: origin.x, y: origin.y, width: 280, height: 16))
        label.stringValue = text
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func updateColorButtonBorder(_ button: NSButton, selected: Bool) {
        if selected {
            button.layer?.borderColor = NSColor.controlAccentColor.cgColor
            button.layer?.borderWidth = 3
        } else {
            button.layer?.borderColor = NSColor.separatorColor.cgColor
            button.layer?.borderWidth = 1
        }
    }

    private func colorsMatch(_ colorA: NSColor, _ colorB: NSColor) -> Bool {
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

    @objc private func appearanceToggleChanged(_ sender: NSSwitch) {
        settingsStore.appearanceAwareColor = (sender.state == .on)
        rebuildWindow()
    }

    @objc private func clickTypeSegmentChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0: selectedClickType = .leftClick
        case 1: selectedClickType = .rightClick
        case 2: selectedClickType = .doubleClick
        default: selectedClickType = .leftClick
        }
        rebuildWindow()
    }

    @objc private func clickTypeEnabledChanged(_ sender: NSSwitch) {
        let enabled = (sender.state == .on)
        switch selectedClickType {
        case .rightClick: settingsStore.rightClickEnabled = enabled
        case .doubleClick: settingsStore.doubleClickEnabled = enabled
        case .leftClick: break
        }
    }

    @objc private func colorSelected(_ sender: NSButton) {
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

    @objc private func lightColorSelected(_ sender: NSButton) {
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

    @objc private func darkColorSelected(_ sender: NSButton) {
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

    @objc private func sizeChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.sizeSteps.count - 1)
        settingsStore.maxRippleSize = Self.sizeSteps[index]
    }

    @objc private func speedChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.speedSteps.count - 1)
        settingsStore.animationDuration = Self.speedSteps[index]
    }

    @objc private func opacityChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.opacitySteps.count - 1)
        settingsStore.rippleOpacity = Self.opacitySteps[index]
    }

    @objc private func resetToDefaults() {
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
        rebuildWindow()
    }

    @objc private func soundToggleChanged(_ sender: NSSwitch) {
        settingsStore.soundEnabled = (sender.state == .on)
        soundPreviewButton?.isEnabled = (sender.state == .on)
    }

    @objc private func soundPreviewPressed(_ sender: NSButton) {
        SoundPlayer.shared.playSound(
            type: settingsStore.soundType, volume: settingsStore.soundVolume)
    }

    @objc private func soundTypeChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        if index >= 0, index < SoundType.allCases.count {
            settingsStore.soundType = SoundType.allCases[index]
        }
        SoundPlayer.shared.playSound(
            type: settingsStore.soundType, volume: settingsStore.soundVolume)
    }

    @objc private func volumeChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.volumeSteps.count - 1)
        settingsStore.soundVolume = Self.volumeSteps[index]
        SoundPlayer.shared.playSound(
            type: settingsStore.soundType, volume: settingsStore.soundVolume)
    }

    @objc private func launchAtLoginChanged(_ sender: NSSwitch) {
        settingsStore.launchAtLogin = (sender.state == .on)
    }

    func windowWillClose(_ notification: Notification) {
        // Keep the window instance for reuse
    }
}
