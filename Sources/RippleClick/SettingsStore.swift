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
        static let launchAtLogin = "launchAtLogin"
    }

    public var isEnabled: Bool {
        get { defaults.object(forKey: Keys.isEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.isEnabled) }
    }

    public var rippleColor: NSColor {
        get {
            guard defaults.object(forKey: Keys.rippleColorRed) != nil else {
                return NSColor(red: 0, green: 1, blue: 1, alpha: 1)  // Cyan
            }
            return NSColor(
                red: defaults.double(forKey: Keys.rippleColorRed),
                green: defaults.double(forKey: Keys.rippleColorGreen),
                blue: defaults.double(forKey: Keys.rippleColorBlue),
                alpha: defaults.double(forKey: Keys.rippleColorAlpha)
            )
        }
        set {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            let color = newValue.usingColorSpace(.sRGB) ?? newValue
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            defaults.set(Double(red), forKey: Keys.rippleColorRed)
            defaults.set(Double(green), forKey: Keys.rippleColorGreen)
            defaults.set(Double(blue), forKey: Keys.rippleColorBlue)
            defaults.set(Double(alpha), forKey: Keys.rippleColorAlpha)
            NotificationCenter.default.post(name: .rippleColorChanged, object: nil)
        }
    }

    public var maxRippleSize: CGFloat {
        get {
            let value = defaults.double(forKey: Keys.maxRippleSize)
            return value > 0 ? value : 100
        }
        set { defaults.set(Double(newValue), forKey: Keys.maxRippleSize) }
    }

    public var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            LoginItemManager.setEnabled(newValue)
            defaults.set(LoginItemManager.isEnabled, forKey: Keys.launchAtLogin)
        }
    }

    private init() {
        self.defaults = UserDefaults.standard
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }
}

extension Notification.Name {
    public static let rippleColorChanged = Notification.Name("rippleColorChanged")
}
