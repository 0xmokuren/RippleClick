import AppKit

extension SettingsViewController {
    // MARK: - Section builders

    func addColorSection(
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
            width: Self.contentWidth - Self.margin * 2, height: 24)
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
                x: Self.contentWidth - Self.margin - toggle.frame.width, y: currentY)
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
            x: Self.contentWidth - Self.margin - toggle.frame.width, y: currentY)
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

    func addSingleColorPalette(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
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

    func addAppearanceAwareColorPalette(
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

    func addSizeSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
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

    func addSpeedSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
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

    func addOpacitySection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
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

    func addSoundSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
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
            x: Self.contentWidth - Self.margin - toggle.frame.width, y: currentY)
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
                width: Self.contentWidth - Self.margin * 2 - 110 - 34, height: 24),
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

    func addGeneralSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
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
        toggle.frame.origin = NSPoint(x: Self.contentWidth - Self.margin - toggle.frame.width, y: currentY)
        toggle.state = settingsStore.launchAtLogin ? .on : .off
        toggle.target = self
        toggle.action = #selector(launchAtLoginChanged(_:))
        self.loginToggle = toggle
        contentView.addSubview(toggle)
        return currentY
    }

    func addBottomButtons(to contentView: NSView, yOffset: CGFloat) {
        let currentY = yOffset - 36
        let resetButton = NSButton(
            title: localized("settings.reset"),
            target: self, action: #selector(resetToDefaults)
        )
        resetButton.bezelStyle = .rounded
        resetButton.sizeToFit()
        resetButton.frame.origin = NSPoint(
            x: Self.contentWidth - resetButton.frame.width - Self.margin,
            y: currentY
        )
        contentView.addSubview(resetButton)

        let quitButton = NSButton(
            title: localized("menu.quit"),
            target: self, action: #selector(quitApp)
        )
        quitButton.bezelStyle = .rounded
        quitButton.sizeToFit()
        quitButton.frame.origin = NSPoint(x: Self.margin, y: currentY)
        contentView.addSubview(quitButton)
    }

    // MARK: - UI helpers

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
