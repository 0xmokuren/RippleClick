import AppKit

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    public static let sizeSteps: [CGFloat] = [30, 70, 100, 150, 200]

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

    private let settingsStore: SettingsStore
    private var window: NSWindow?
    private var sizeLabel: NSTextField?
    private var sizeSlider: NSSlider?
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

        let width: CGFloat = 320
        let height: CGFloat = 248
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L("settings.title")
        window.delegate = self
        window.center()
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = contentView

        var y = height - 32

        // --- Color section ---
        let colorLabel = makeSectionLabel(L("settings.color"), origin: NSPoint(x: 20, y: y))
        contentView.addSubview(colorLabel)

        let buttonSize: CGFloat = 28
        let buttonSpacing: CGFloat = 8
        colorButtons = []

        for row in 0..<2 {
            y -= (buttonSize + 4)
            for col in 0..<6 {
                let index = row * 6 + col
                let preset = Self.colorPresets[index]
                let x = 20 + CGFloat(col) * (buttonSize + buttonSpacing)

                let button = NSButton(
                    frame: NSRect(x: x, y: y, width: buttonSize, height: buttonSize)
                )
                button.title = ""
                button.bezelStyle = .circular
                button.isBordered = false
                button.wantsLayer = true
                button.layer?.cornerRadius = buttonSize / 2
                button.layer?.backgroundColor = preset.color.cgColor
                button.toolTip = L(preset.key)
                button.tag = index
                button.target = self
                button.action = #selector(colorSelected(_:))

                updateColorButtonBorder(
                    button,
                    selected: colorsMatch(preset.color, settingsStore.rippleColor)
                )
                colorButtons.append(button)
                contentView.addSubview(button)
            }
        }

        // --- Size section ---
        y -= 28
        let sizeTitle = makeSectionLabel(L("settings.size"), origin: NSPoint(x: 20, y: y))
        contentView.addSubview(sizeTitle)

        y -= 28
        let slider = NSSlider(
            frame: NSRect(x: 20, y: y, width: 200, height: 24)
        )
        slider.minValue = 0
        slider.maxValue = Double(Self.sizeSteps.count - 1)
        slider.integerValue = Self.sizeSteps.firstIndex(of: settingsStore.maxRippleSize) ?? 2
        slider.numberOfTickMarks = Self.sizeSteps.count
        slider.allowsTickMarkValuesOnly = true
        slider.target = self
        slider.action = #selector(sizeChanged(_:))
        self.sizeSlider = slider
        contentView.addSubview(slider)

        let currentIndex = Self.sizeSteps.firstIndex(of: settingsStore.maxRippleSize) ?? 2
        let valueLabel = NSTextField(
            frame: NSRect(x: 228, y: y + 2, width: 30, height: 20)
        )
        valueLabel.stringValue = "\(currentIndex + 1)"
        valueLabel.isEditable = false
        valueLabel.isBezeled = false
        valueLabel.drawsBackground = false
        valueLabel.alignment = .center
        valueLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        self.sizeLabel = valueLabel
        contentView.addSubview(valueLabel)

        // --- General section ---
        y -= 28
        let generalLabel = makeSectionLabel(L("settings.general"), origin: NSPoint(x: 20, y: y))
        contentView.addSubview(generalLabel)

        y -= 24
        let loginCheckbox = NSButton(
            checkboxWithTitle: L("settings.launchAtLogin"),
            target: self, action: #selector(launchAtLoginChanged(_:))
        )
        loginCheckbox.frame = NSRect(x: 20, y: y, width: 200, height: 20)
        loginCheckbox.state = settingsStore.launchAtLogin ? .on : .off
        self.loginCheckbox = loginCheckbox
        contentView.addSubview(loginCheckbox)

        // --- Reset button ---
        y -= 36
        let resetButton = NSButton(
            title: L("settings.reset"),
            target: self, action: #selector(resetToDefaults)
        )
        resetButton.bezelStyle = .rounded
        resetButton.sizeToFit()
        resetButton.frame.origin = NSPoint(
            x: width - resetButton.frame.width - 20,
            y: y
        )
        contentView.addSubview(resetButton)

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - UI helpers

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

    // MARK: - Actions

    @objc private func colorSelected(_ sender: NSButton) {
        let preset = Self.colorPresets[sender.tag]
        settingsStore.rippleColor = preset.color

        for button in colorButtons {
            updateColorButtonBorder(button, selected: button.tag == sender.tag)
        }
    }

    private func updateColorButtonBorder(_ button: NSButton, selected: Bool) {
        button.layer?.borderColor = selected
            ? NSColor.controlAccentColor.cgColor
            : NSColor.separatorColor.cgColor
        button.layer?.borderWidth = selected ? 3 : 1
    }

    private func colorsMatch(_ a: NSColor, _ b: NSColor) -> Bool {
        guard let a = a.usingColorSpace(.sRGB), let b = b.usingColorSpace(.sRGB) else {
            return false
        }
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1 - r2) < 0.05 && abs(g1 - g2) < 0.05 && abs(b1 - b2) < 0.05
    }

    @objc private func sizeChanged(_ sender: NSSlider) {
        let index = min(sender.integerValue, Self.sizeSteps.count - 1)
        let value = Self.sizeSteps[index]
        settingsStore.maxRippleSize = value
        sizeLabel?.stringValue = "\(index + 1)"
    }

    @objc private func resetToDefaults() {
        settingsStore.rippleColor = Self.colorPresets[0].color
        for button in colorButtons {
            updateColorButtonBorder(button, selected: button.tag == 0)
        }

        settingsStore.maxRippleSize = Self.sizeSteps[2]
        sizeSlider?.integerValue = 2
        sizeLabel?.stringValue = "3"

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
