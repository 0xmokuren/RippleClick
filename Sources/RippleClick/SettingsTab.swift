/// 設定ポップオーバーのタブ。rawValue は NSSegmentedControl のセグメント番号と一致させる。
public enum SettingsTab: Int, CaseIterable {
    case ripple
    case color
    case sound
    case general

    public var titleKey: String {
        switch self {
        case .ripple: return "settings.tab.ripple"
        case .color: return "settings.tab.color"
        case .sound: return "settings.tab.sound"
        case .general: return "settings.tab.general"
        }
    }
}
