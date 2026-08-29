import Combine
import Foundation

/// In-app language preference. Default follows the macOS language.
@MainActor
final class AppLanguageSettings: ObservableObject {
    static let shared = AppLanguageSettings()

    enum Preference: String, CaseIterable, Identifiable {
        case system
        case english
        case russian

        var id: String { rawValue }

        /// BCP-47 code written to `AppleLanguages`, or `nil` for system default.
        var languageCode: String? {
            switch self {
            case .system: return nil
            case .english: return "en"
            case .russian: return "ru"
            }
        }
    }

    private static let storageKey = "appLanguage.preference"
    private static let supportedLanguageCodes = ["en", "ru"]

    @Published private(set) var preference: Preference

    /// Locale used for formatting and SwiftUI environment.
    var locale: Locale {
        Locale(identifier: resolvedLanguageCode)
    }

    /// Stable id to force SwiftUI view refresh when language changes.
    var refreshID: String {
        "\(preference.rawValue):\(resolvedLanguageCode)"
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? Preference.system.rawValue
        preference = Preference(rawValue: raw) ?? .system
        apply()
    }

    func setPreference(_ newValue: Preference) {
        guard preference != newValue else { return }
        preference = newValue
        UserDefaults.standard.set(newValue.rawValue, forKey: Self.storageKey)
        apply()
    }

    private var resolvedLanguageCode: String {
        if let code = preference.languageCode {
            return code
        }
        return Self.bestSupportedCode(from: Self.systemLanguageCodes)
    }

    private func apply() {
        let code = resolvedLanguageCode
        let locale = Locale(identifier: code)

        if preference.languageCode != nil {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }

        AppLocale.current = locale
        AppLocale.languageCode = code
        LocalizationBundle.refresh()
        DurationFormat.setLocale(locale)
        objectWillChange.send()
    }

    /// System UI languages ignoring this app’s `AppleLanguages` override.
    private static var systemLanguageCodes: [String] {
        let global = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        if let languages = global?["AppleLanguages"] as? [String], !languages.isEmpty {
            return languages
        }
        return Locale.preferredLanguages
    }

    private static func bestSupportedCode(from preferred: [String]) -> String {
        for raw in preferred {
            let code = Locale(identifier: raw).language.languageCode?.identifier ?? raw
            if supportedLanguageCodes.contains(code) {
                return code
            }
            if let match = supportedLanguageCodes.first(where: { raw.hasPrefix($0) }) {
                return match
            }
        }
        return "en"
    }
}

/// Process-wide locale for formatters / `L(…)` outside the main actor.
enum AppLocale {
    nonisolated(unsafe) static var current: Locale = Locale(identifier: "en")
    nonisolated(unsafe) static var languageCode: String = "en"
}

/// Explicit String Catalog lookup that respects the in-app language.
enum LocalizationBundle {
    nonisolated(unsafe) private static var cachedBundle: Bundle = .main
    nonisolated(unsafe) private static var cachedCode: String = ""

    static func refresh() {
        cachedCode = ""
        _ = stringsBundle
    }

    static var stringsBundle: Bundle {
        let code = AppLocale.languageCode
        if code == cachedCode {
            return cachedBundle
        }
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            cachedBundle = bundle
            cachedCode = code
            return bundle
        }
        cachedBundle = .main
        cachedCode = code
        return .main
    }
}

/// Localized string using the active app language (works for interpolated keys too).
///
/// Single localization path for the app:
/// - UI: `Text(L("key"))`, `Button(L("key"))`, `Label(L("key"), …)`
/// - Non-UI `String`: `L("key")` / `L("key \(value)")`
/// Do not call `String(localized:)` or bare `Text("key")` for catalog strings.
func L(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: LocalizationBundle.stringsBundle, locale: AppLocale.current)
}
