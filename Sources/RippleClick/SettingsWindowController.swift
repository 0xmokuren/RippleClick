import AppKit

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let sizeSteps: [CGFloat] = [30, 70, 100, 150, 200]
    public static let speedSteps: [CFTimeInterval] = [0.25, 0.35, 0.5, 0.7, 1.0]
    public static let opacitySteps: [CGFloat] = [0.2, 0.4, 0.6, 0.8, 1.0]

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

    private static let windowWidth: CGFloat = 320
    private static let windowHeight: CGFloat = 440
    private static let margin: CGFloat = 20
    private static let colorButtonSize: CGFloat = 28
    private static let colorButtonSpacing: CGFloat = 8

    private let settingsStore: SettingsStore
    private var window: NSWindow?
    private var sizeSlider: NSSlider?
    private var speedSlider: NSSlider?
    private var opacitySlider: NSSlider?
    private var loginCheckbox: NSButton?
    private var colorButtons: [NSButton] = []

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

        let window = createWindow()
        let contentView = NSView(
            frame: NSRect(x: 0, y: 0, width: Self.windowWidth, height: Self.windowHeight)
        )
        window.contentView = contentView

        var yOffset = Self.windowHeight - 32
        yOffset = addColorSection(to: contentView, yOffset: yOffset)
        yOffset = addSizeSection(to: contentView, yOffset: yOffset)
        yOffset = addSpeedSection(to: contentView, yOffset: yOffset)
        yOffset = addOpacitySection(to: contentView, yOffset: yOffset)
        yOffset = addGeneralSection(to: contentView, yOffset: yOffset)
        addResetButton(to: contentView, yOffset: yOffset)

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Window creation

    private func createWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.windowWidth, height: Self.windowHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = localized("settings.title")
        window.delegate = self
        window.center()
        window.isReleasedWhenClosed = false
        return window
    }

    // MARK: - Section builders

    private func addColorSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset
        let label = makeSectionLabel(localized("settings.color"), origin: NSPoint(x: Self.margin, y: currentY))
        contentView.addSubview(label)

        colorButtons = []
        for row in 0..<2 {
            currentY -= (Self.colorButtonSize + 4)
            for col in 0..<6 {
                let index = row * 6 + col
                let preset = Self.colorPresets[index]
                let xPos = Self.margin + CGFloat(col) * (Self.colorButtonSize + Self.colorButtonSpacing)

                let button = makeColorButton(
                    frame: NSRect(x: xPos, y: currentY, width: Self.colorButtonSize, height: Self.colorButtonSize),
                    preset: preset,
                    index: index
                )
                colorButtons.append(button)
                contentView.addSubview(button)
            }
        }
        return currentY
    }

    private func addSizeSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset - 28
        let title = makeSectionLabel(localized("settings.size"), origin: NSPoint(x: Self.margin, y: currentY))
        contentView.addSubview(title)

        currentY -= 28
        let slider = NSSlider(frame: NSRect(x: Self.margin, y: currentY, width: 200, height: 24))
        slider.minValue = 0
        slider.maxValue = Double(Self.sizeSteps.count - 1)
        slider.integerValue = Self.sizeSteps.firstIndex(of: settingsStore.maxRippleSize) ?? 2
        slider.numberOfTickMarks = Self.sizeSteps.count
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action = #selector(sizeChanged(_:))
        self.sizeSlider = slider
        contentView.addSubview(slider)

        currentY -= 16
        addEdgeLabels(
            to: contentView,
            y: currentY,
            minText: localized("settings.size.min"),
            maxText: localized("settings.size.max"),
            sliderWidth: 200
        )

        return currentY
    }

    private func addSpeedSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset - 28
        let title = makeSectionLabel(localized("settings.speed"), origin: NSPoint(x: Self.margin, y: currentY))
        contentView.addSubview(title)

        currentY -= 28
        let slider = NSSlider(frame: NSRect(x: Self.margin, y: currentY, width: 200, height: 24))
        slider.minValue = 0
        slider.maxValue = Double(Self.speedSteps.count - 1)
        slider.integerValue = Self.speedSteps.firstIndex(of: settingsStore.animationDuration) ?? 2
        slider.numberOfTickMarks = Self.speedSteps.count
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action = #selector(speedChanged(_:))
        self.speedSlider = slider
        contentView.addSubview(slider)

        currentY -= 16
        addEdgeLabels(
            to: contentView,
            y: currentY,
            minText: localized("settings.speed.min"),
            maxText: localized("settings.speed.max"),
            sliderWidth: 200
        )

        return currentY
    }

    private func addOpacitySection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset - 28
        let title = makeSectionLabel(localized("settings.opacity"), origin: NSPoint(x: Self.margin, y: currentY))
        contentView.addSubview(title)

        currentY -= 28
        let slider = NSSlider(frame: NSRect(x: Self.margin, y: currentY, width: 200, height: 24))
        slider.minValue = 0
        slider.maxValue = Double(Self.opacitySteps.count - 1)
        slider.integerValue = Self.opacitySteps.firstIndex(of: settingsStore.rippleOpacity) ?? 4
        slider.numberOfTickMarks = Self.opacitySteps.count
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action = #selector(opacityChanged(_:))
        self.opacitySlider = slider
        contentView.addSubview(slider)

        currentY -= 16
        addEdgeLabels(
            to: contentView,
            y: currentY,
            minText: localized("settings.opacity.min"),
            maxText: localized("settings.opacity.max"),
            sliderWidth: 200
        )

        return currentY
    }

    private func addGeneralSection(to contentView: NSView, yOffset: CGFloat) -> CGFloat {
        var currentY = yOffset - 28
        let label = makeSectionLabel(localized("settings.general"), origin: NSPoint(x: Self.margin, y: currentY))
        contentView.addSubview(label)

        currentY -= 24
        let checkbox = NSButton(
            checkboxWithTitle: localized("settings.launchAtLogin"),
            target: self, action: #selector(launchAtLoginChanged(_:))
        )
        checkbox.frame = NSRect(x: Self.margin, y: currentY, width: 200, height: 20)
        checkbox.state = settingsStore.launchAtLogin ? .on : .off
        self.loginCheckbox = checkbox
        contentView.addSubview(checkbox)

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
        index: Int
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
        button.action = #selector(colorSelected(_:))
        updateColorButtonBorder(button, selected: colorsMatch(preset.color, settingsStore.rippleColor))
        return button
    }

    private func addEdgeLabels(
        to contentView: NSView,
        y: CGFloat,
        minText: String,
        maxText: String,
        sliderWidth: CGFloat
    ) {
        let minLabel = NSTextField(frame: NSRect(x: Self.margin, y: y, width: 60, height: 14))
        minLabel.stringValue = minText
        minLabel.isEditable = false
        minLabel.isBezeled = false
        minLabel.drawsBackground = false
        minLabel.alignment = .left
        minLabel.font = .systemFont(ofSize: 10)
        minLabel.textColor = .tertiaryLabelColor
        contentView.addSubview(minLabel)

        let maxLabel = NSTextField(
            frame: NSRect(x: Self.margin + sliderWidth - 60, y: y, width: 60, height: 14)
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

    private func makeSectionLabel(_ text: String, origin: NSPoint) -> NSTextField {
        let label = NSTextField(frame: NSRect(x: origin.x, y: origin.y, width: 280, height: 18))
        label.stringValue = text
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
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
        return abs(red1 - red2) < 0.05 && abs(green1 - green2) < 0.05 && abs(blue1 - blue2) < 0.05
    }

    // MARK: - Actions

    @objc private func colorSelected(_ sender: NSButton) {
        let preset = Self.colorPresets[sender.tag]
        settingsStore.rippleColor = preset.color

        for button in colorButtons {
            updateColorButtonBorder(button, selected: button.tag == sender.tag)
        }
    }

    @objc private func sizeChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.sizeSteps.count - 1)
        let value = Self.sizeSteps[index]
        settingsStore.maxRippleSize = value
    }

    @objc private func speedChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.speedSteps.count - 1)
        let value = Self.speedSteps[index]
        settingsStore.animationDuration = value
    }

    @objc private func opacityChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.opacitySteps.count - 1)
        let value = Self.opacitySteps[index]
        settingsStore.rippleOpacity = value
    }

    @objc private func resetToDefaults() {
        settingsStore.rippleColor = Self.colorPresets[0].color
        for button in colorButtons {
            updateColorButtonBorder(button, selected: button.tag == 0)
        }

        settingsStore.maxRippleSize = Self.sizeSteps[2]
        sizeSlider?.integerValue = 2

        settingsStore.animationDuration = Self.speedSteps[2]
        speedSlider?.integerValue = 2

        settingsStore.rippleOpacity = Self.opacitySteps[4]
        opacitySlider?.integerValue = 4

        settingsStore.launchAtLogin = false
        loginCheckbox?.state = .off
    }

    @objc private func launchAtLoginChanged(_ sender: NSButton) {
        settingsStore.launchAtLogin = (sender.state == .on)
    }

    func windowWillClose(_ notification: Notification) {
        // Keep the window instance for reuse
    }
}
