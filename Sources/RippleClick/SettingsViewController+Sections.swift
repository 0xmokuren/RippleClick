import AppKit

extension SettingsViewController {
    /// スライダーセクション1つ分の内容。引数の数を抑えるためにまとめている。
    struct SliderSectionSpec {
        let title: String
        let symbolName: String
        let stepCount: Int
        let selectedIndex: Int
        let action: Selector
        let minText: String
        let maxText: String
    }

    // MARK: - Ripple tab

    func addSizeSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        let section = addSliderSection(
            to: contentView, yOffset: yOffset,
            spec: SliderSectionSpec(
                title: localized("settings.size"),
                symbolName: "arrow.up.left.and.arrow.down.right",
                stepCount: Self.sizeSteps.count,
                selectedIndex: nearestIndex(for: settingsStore.maxRippleSize, in: Self.sizeSteps),
                action: #selector(sizeChanged(_:)),
                minText: localized("settings.size.min"),
                maxText: localized("settings.size.max")
            )
        )
        self.sizeSlider = section.slider
        return section.nextY
    }

    func addSpeedSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        let section = addSliderSection(
            to: contentView, yOffset: yOffset,
            spec: SliderSectionSpec(
                title: localized("settings.speed"),
                symbolName: "hare",
                stepCount: Self.speedSteps.count,
                selectedIndex: nearestIndex(
                    for: settingsStore.animationDuration, in: Self.speedSteps),
                action: #selector(speedChanged(_:)),
                minText: localized("settings.speed.min"),
                maxText: localized("settings.speed.max")
            )
        )
        self.speedSlider = section.slider
        return section.nextY
    }

    func addOpacitySection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        let section = addSliderSection(
            to: contentView, yOffset: yOffset,
            spec: SliderSectionSpec(
                title: localized("settings.opacity"),
                symbolName: "circle.lefthalf.filled",
                stepCount: Self.opacitySteps.count,
                selectedIndex: nearestIndex(
                    for: settingsStore.rippleOpacity, in: Self.opacitySteps),
                action: #selector(opacityChanged(_:)),
                minText: localized("settings.opacity.min"),
                maxText: localized("settings.opacity.max")
            )
        )
        self.opacitySlider = section.slider
        return section.nextY
    }

    // MARK: - Color tab

    func addColorSection(
        to contentView: NSView, yOffset: CGFloat, appearanceAware: Bool
    ) -> CGFloat {
        var currentY = yOffset

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
        segmentedControl.segmentDistribution = .fillEqually
        segmentedControl.frame = NSRect(
            x: Self.margin, y: currentY,
            width: Self.contentWidth - Self.margin * 2, height: 24)
        contentView.addSubview(segmentedControl)

        if selectedClickType != .leftClick {
            currentY -= 32
            self.clickTypeEnabledToggle = addToggleRow(
                to: contentView, yOffset: currentY,
                title: selectedClickType == .rightClick
                    ? localized("settings.clickType.rightEnabled")
                    : localized("settings.clickType.doubleEnabled"),
                isOn: selectedClickType == .rightClick
                    ? settingsStore.rightClickEnabled : settingsStore.doubleClickEnabled,
                action: #selector(clickTypeEnabledChanged(_:))
            )
        }

        currentY -= 28
        self.appearanceToggle = addToggleRow(
            to: contentView, yOffset: currentY,
            title: localized("settings.color.appearance"),
            isOn: appearanceAware,
            action: #selector(appearanceToggleChanged(_:))
        )

        if appearanceAware {
            currentY = addAppearanceAwareColorPalette(to: contentView, yOffset: currentY)
        } else {
            currentY = addSingleColorPalette(to: contentView, yOffset: currentY)
        }
        return currentY
    }

    func addSingleColorPalette(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset
        let selectedColor = currentSelectedColor()
        colorButtons = []
        for row in 0..<2 {
            currentY -= (Self.colorButtonSize + 4)
            for col in 0..<6 {
                let index = row * 6 + col
                let button = makeColorButton(
                    frame: colorButtonFrame(column: col, yPosition: currentY),
                    preset: Self.colorPresets[index],
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

    func addAppearanceAwareColorPalette(
        to contentView: NSView, yOffset: CGFloat
    ) -> CGFloat {
        var currentY = yOffset

        currentY -= 24
        contentView.addSubview(
            makeSubLabel(
                localized("settings.color.light"),
                origin: NSPoint(x: Self.margin + 8, y: currentY)))

        lightColorButtons = []
        let lightColor = currentLightColor()
        for row in 0..<2 {
            currentY -= (Self.colorButtonSize + 4)
            for col in 0..<6 {
                let index = row * 6 + col
                let button = makeColorButton(
                    frame: colorButtonFrame(column: col, yPosition: currentY),
                    preset: Self.colorPresets[index],
                    index: index,
                    action: #selector(lightColorSelected(_:)),
                    selectedColor: lightColor
                )
                lightColorButtons.append(button)
                contentView.addSubview(button)
            }
        }

        currentY -= 24
        contentView.addSubview(
            makeSubLabel(
                localized("settings.color.dark"),
                origin: NSPoint(x: Self.margin + 8, y: currentY)))

        darkColorButtons = []
        let darkColor = currentDarkColor()
        for row in 0..<2 {
            currentY -= (Self.colorButtonSize + 4)
            for col in 0..<6 {
                let index = row * 6 + col
                let button = makeColorButton(
                    frame: colorButtonFrame(column: col, yPosition: currentY),
                    preset: Self.colorPresets[index],
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

    // MARK: - Sound tab

    func addSoundSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset

        self.soundToggle = addToggleRow(
            to: contentView, yOffset: currentY,
            title: localized("settings.sound.enabled"),
            isOn: settingsStore.soundEnabled,
            action: #selector(soundToggleChanged(_:))
        )

        currentY -= 30
        contentView.addSubview(
            makeRowLabel(
                localized("settings.sound.type"),
                origin: NSPoint(x: Self.margin, y: currentY), width: 100))

        let previewButtonWidth: CGFloat = 30
        let popUpX = Self.margin + 110
        let popUpWidth =
            Self.contentWidth - Self.margin - popUpX - previewButtonWidth - 4
        let popUp = NSPopUpButton(
            frame: NSRect(x: popUpX, y: currentY - 2, width: popUpWidth, height: 24),
            pullsDown: false)
        for soundType in SoundType.allCases {
            popUp.addItem(withTitle: localized("sound.type.\(soundType.rawValue)"))
        }
        popUp.selectItem(at: SoundType.allCases.firstIndex(of: settingsStore.soundType) ?? 0)
        popUp.target = self
        popUp.action = #selector(soundTypeChanged(_:))
        self.soundTypePopUp = popUp
        contentView.addSubview(popUp)

        let previewButton = NSButton(
            frame: NSRect(
                x: popUpX + popUpWidth + 4, y: currentY - 2,
                width: previewButtonWidth, height: 24))
        previewButton.image = NSImage(
            systemSymbolName: "play.circle",
            accessibilityDescription: localized("settings.sound.preview"))
        previewButton.bezelStyle = .accessoryBarAction
        previewButton.imagePosition = .imageOnly
        previewButton.toolTip = localized("settings.sound.preview")
        previewButton.target = self
        previewButton.action = #selector(soundPreviewPressed(_:))
        self.soundPreviewButton = previewButton
        contentView.addSubview(previewButton)

        let volume = addSliderSection(
            to: contentView, yOffset: currentY - Self.sectionGap,
            spec: SliderSectionSpec(
                title: localized("settings.sound.volume"),
                symbolName: "speaker.wave.2",
                stepCount: Self.volumeSteps.count,
                selectedIndex: nearestIndex(for: settingsStore.soundVolume, in: Self.volumeSteps),
                action: #selector(volumeChanged(_:)),
                minText: localized("settings.sound.volume.min"),
                maxText: localized("settings.sound.volume.max")
            )
        )
        self.volumeSlider = volume.slider

        updateSoundControlsEnabled()
        return volume.nextY
    }

    // MARK: - General tab

    func addGeneralSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset

        self.loginToggle = addToggleRow(
            to: contentView, yOffset: currentY,
            title: localized("settings.launchAtLogin"),
            isOn: settingsStore.launchAtLogin,
            action: #selector(launchAtLoginChanged(_:))
        )

        currentY -= 20
        contentView.addSubview(
            makeSeparator(
                width: Self.contentWidth - Self.margin * 2, yPosition: currentY,
                xPosition: Self.margin))

        let actions: [(title: String, action: Selector)] = [
            (localized("settings.reset"), #selector(resetToDefaults)),
            (localized("menu.about"), #selector(showAboutPanel)),
            (localized("menu.quit"), #selector(quitApp)),
        ]
        for entry in actions {
            currentY -= 36
            addWideButton(
                to: contentView, yOffset: currentY, title: entry.title, action: entry.action)
        }
        return currentY
    }

    // MARK: - Row builders

    /// タイトル + スライダー + 両端ラベルの1セクション。返り値の nextY は両端ラベルの y。
    private func addSliderSection(
        to contentView: NSView, yOffset: CGFloat, spec: SliderSectionSpec
    ) -> (slider: NSSlider, nextY: CGFloat) {
        var currentY = yOffset
        contentView.addSubview(
            makeSectionLabel(
                spec.title, origin: NSPoint(x: Self.margin, y: currentY),
                symbolName: spec.symbolName))

        currentY -= 28
        let sliderWidth = Self.contentWidth - Self.margin * 2
        let slider = NSSlider(
            frame: NSRect(x: Self.margin, y: currentY, width: sliderWidth, height: 24))
        slider.minValue = 0
        slider.maxValue = Double(spec.stepCount - 1)
        slider.integerValue = spec.selectedIndex
        slider.numberOfTickMarks = spec.stepCount
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action = spec.action
        contentView.addSubview(slider)

        currentY -= 16
        addEdgeLabels(
            to: contentView, yPosition: currentY,
            minText: spec.minText, maxText: spec.maxText, sliderWidth: sliderWidth)
        return (slider, currentY)
    }

    /// 左にラベル、右端に NSSwitch を置く1行。行の高さは rowHeight。
    private func addToggleRow(
        to contentView: NSView, yOffset: CGFloat, title: String, isOn: Bool, action: Selector
    ) -> NSSwitch {
        contentView.addSubview(
            makeRowLabel(title, origin: NSPoint(x: Self.margin, y: yOffset), width: 260))

        let toggle = NSSwitch()
        toggle.controlSize = .small
        toggle.sizeToFit()
        toggle.frame.origin = NSPoint(
            x: Self.contentWidth - Self.margin - toggle.frame.width, y: yOffset)
        toggle.state = isOn ? .on : .off
        toggle.target = self
        toggle.action = action
        contentView.addSubview(toggle)
        return toggle
    }

    private func addWideButton(
        to contentView: NSView, yOffset: CGFloat, title: String, action: Selector
    ) {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.frame = NSRect(
            x: Self.margin, y: yOffset,
            width: Self.contentWidth - Self.margin * 2, height: 28)
        contentView.addSubview(button)
    }

    // MARK: - UI helpers

    private func colorButtonFrame(column: Int, yPosition: CGFloat) -> NSRect {
        let xPos =
            Self.margin + CGFloat(column) * (Self.colorButtonSize + Self.colorButtonSpacing)
        return NSRect(
            x: xPos, y: yPosition, width: Self.colorButtonSize, height: Self.colorButtonSize)
    }

    func makeColorButton(
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

    func addEdgeLabels(
        to contentView: NSView, yPosition: CGFloat,
        minText: String, maxText: String, sliderWidth: CGFloat
    ) {
        let minLabel = NSTextField(
            frame: NSRect(x: Self.margin, y: yPosition, width: 80, height: 14))
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
                x: Self.margin + sliderWidth - 80, y: yPosition, width: 80, height: 14)
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

    func makeSectionLabel(
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

    func makeRowLabel(_ text: String, origin: NSPoint, width: CGFloat) -> NSTextField {
        let label = NSTextField(
            frame: NSRect(x: origin.x, y: origin.y, width: width, height: Self.rowHeight))
        label.stringValue = text
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 13)
        return label
    }

    func makeSubLabel(_ text: String, origin: NSPoint) -> NSTextField {
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

    func makeSeparator(width: CGFloat, yPosition: CGFloat, xPosition: CGFloat = 0) -> NSBox {
        let separator = NSBox(
            frame: NSRect(x: xPosition, y: yPosition, width: width, height: 1))
        separator.boxType = .separator
        return separator
    }

    func updateColorButtonBorder(_ button: NSButton, selected: Bool) {
        if selected {
            button.layer?.borderColor = NSColor.controlAccentColor.cgColor
            button.layer?.borderWidth = 3
        } else {
            button.layer?.borderColor = NSColor.separatorColor.cgColor
            button.layer?.borderWidth = 1
        }
    }
}
