import Foundation

private let localizedBundle: Bundle = {
    let module = Bundle.module
    let supported = module.localizations
    let preferred = Bundle.preferredLocalizations(from: supported)
    if let lang = preferred.first,
        let path = module.path(forResource: lang, ofType: "lproj"),
        let bundle = Bundle(path: path)
    {
        return bundle
    }
    return module
}()

func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: localizedBundle, comment: "")
}
