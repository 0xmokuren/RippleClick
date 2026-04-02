import AppKit

@MainActor
public final class SettingsStore {
    public static let shared = SettingsStore()

    private let defaults: UserDefaults

    private enum Keys {
        static let isEnabled = "isEnabled"
        static let rippleColorRed = "rippleColorRed"
        static let rippleColorGreen = "rippleColorGreen"
        static let rippleColorBlue = "rippleColorBlue"
        static let rippleColorAlpha = "rippleColorAlpha"
        static let maxRippleSize = "maxRippleSize"
        static let animationDuration = "animationDuration"
        static let rippleOpacity = "rippleOpacity"
        static let launchAtLogin = "launchAtLogin"
        static let appearanceAwareColor = "appearanceAwareColor"
        static let lightColorRed = "lightColorRed"
        static let lightColorGreen = "lightColorGreen"
        static let lightColorBlue = "lightColorBlue"
        static let lightColorAlpha = "lightColorAlpha"
        static let darkColorRed = "darkColorRed"
        static let darkColorGreen = "darkColorGreen"
        static let darkColorBlue = "darkColorBlue"
        static let darkColorAlpha = "darkColorAlpha"
    }

    private static let defaultColor = NSColor(red: 0, green: 1, blue: 1, alpha: 1)  // Cyan

    public var isEnabled: Bool {
        get { defaults.object(forKey: Keys.isEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.isEnabled) }
    }

    public var appearanceAwareColor: Bool {
        get { defaults.bool(forKey: Keys.appearanceAwareColor) }
        set {
            defaults.set(newValue, forKey: Keys.appearanceAwareColor)
            NotificationCenter.default.post(name: .rippleColorChanged, object: nil)
        }
    }

    public var rippleColor: NSColor {
        get {
            if appearanceAwareColor {
                return isDarkMode ? darkModeColor : lightModeColor
            }
            guard defaults.object(forKey: Keys.rippleColorRed) != nil else {
                return Self.defaultColor
            }
            return NSColor(
                red: defaults.double(forKey: Keys.rippleColorRed),
                green: defaults.double(forKey: Keys.rippleColorGreen),
                blue: defaults.double(forKey: Keys.rippleColorBlue),
                alpha: defaults.double(forKey: Keys.rippleColorAlpha)
            )
        }
        set {
            storeColor(newValue, redKey: Keys.rippleColorRed, greenKey: Keys.rippleColorGreen,
                        blueKey: Keys.rippleColorBlue, alphaKey: Keys.rippleColorAlpha)
            NotificationCenter.default.post(name: .rippleColorChanged, object: nil)
        }
    }

    public var lightModeColor: NSColor {
        get { loadColor(redKey: Keys.lightColorRed, greenKey: Keys.lightColorGreen,
                        blueKey: Keys.lightColorBlue, alphaKey: Keys.lightColorAlpha) }
        set {
            storeColor(newValue, redKey: Keys.lightColorRed, greenKey: Keys.lightColorGreen,
                        blueKey: Keys.lightColorBlue, alphaKey: Keys.lightColorAlpha)
            if appearanceAwareColor {
                NotificationCenter.default.post(name: .rippleColorChanged, object: nil)
            }
        }
    }

    public var darkModeColor: NSColor {
        get { loadColor(redKey: Keys.darkColorRed, greenKey: Keys.darkColorGreen,
                        blueKey: Keys.darkColorBlue, alphaKey: Keys.darkColorAlpha) }
        set {
            storeColor(newValue, redKey: Keys.darkColorRed, greenKey: Keys.darkColorGreen,
                        blueKey: Keys.darkColorBlue, alphaKey: Keys.darkColorAlpha)
            if appearanceAwareColor {
                NotificationCenter.default.post(name: .rippleColorChanged, object: nil)
            }
        }
    }

    public var isDarkMode: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    }

    public var maxRippleSize: CGFloat {
        get {
            let value = defaults.double(forKey: Keys.maxRippleSize)
            return value > 0 ? value : 100
        }
        set { defaults.set(Double(max(10, min(newValue, 500))), forKey: Keys.maxRippleSize) }
    }

    public var rippleOpacity: CGFloat {
        get {
            let value = defaults.double(forKey: Keys.rippleOpacity)
            return value > 0 ? CGFloat(value) : 0.6
        }
        set { defaults.set(Double(max(0.1, min(newValue, 1.0))), forKey: Keys.rippleOpacity) }
    }

    public var animationDuration: CFTimeInterval {
        get {
            let value = defaults.double(forKey: Keys.animationDuration)
            return value > 0 ? value : 0.5
        }
        set { defaults.set(Double(max(0.1, min(newValue, 2.0))), forKey: Keys.animationDuration) }
    }

    public var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            let success = LoginItemManager.setEnabled(newValue)
            defaults.set(success ? newValue : LoginItemManager.isEnabled, forKey: Keys.launchAtLogin)
        }
    }

    private init() {
        self.defaults = UserDefaults.standard
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    // MARK: - Color helpers

    private func loadColor(
        redKey: String, greenKey: String, blueKey: String, alphaKey: String
    ) -> NSColor {
        guard defaults.object(forKey: redKey) != nil else {
            return Self.defaultColor
        }
        return NSColor(
            red: defaults.double(forKey: redKey),
            green: defaults.double(forKey: greenKey),
            blue: defaults.double(forKey: blueKey),
            alpha: defaults.double(forKey: alphaKey)
        )
    }

    private func storeColor(
        _ color: NSColor, redKey: String, greenKey: String, blueKey: String, alphaKey: String
    ) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let srgb = color.usingColorSpace(.sRGB) ?? color
        srgb.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        defaults.set(Double(red), forKey: redKey)
        defaults.set(Double(green), forKey: greenKey)
        defaults.set(Double(blue), forKey: blueKey)
        defaults.set(Double(alpha), forKey: alphaKey)
    }
}

extension Notification.Name {
    public static let rippleColorChanged = Notification.Name("rippleColorChanged")
}
