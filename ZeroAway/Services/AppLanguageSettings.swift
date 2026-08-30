import Combine
import Foundation
import SwiftUI

/// In-app language preference. Default follows the macOS language.
@MainActor
final class AppLanguageSettings: ObservableObject {
    static let shared = AppLanguageSettings()

    enum Preference: String, CaseIterable, Identifiable {
        case system
        case english
        case russian
        case german
        case french
        case spanish
        case portugueseBrazil
        case italian
        case dutch
        case polish
        case czech
        case romanian
        case turkish
        case ukrainian
        case japanese
        case chineseSimplified
        case korean
        case arabic
        case hebrew
        case persian
        case vietnamese
        case indonesian

        var id: String { rawValue }

        /// BCP-47 code written to `AppleLanguages`, or `nil` for system default.
        var languageCode: String? {
            switch self {
            case .system: return nil
            case .english: return "en"
            case .russian: return "ru"
            case .german: return "de"
            case .french: return "fr"
            case .spanish: return "es"
            case .portugueseBrazil: return "pt-BR"
            case .italian: return "it"
            case .dutch: return "nl"
            case .polish: return "pl"
            case .czech: return "cs"
            case .romanian: return "ro"
            case .turkish: return "tr"
            case .ukrainian: return "uk"
            case .japanese: return "ja"
            case .chineseSimplified: return "zh-Hans"
            case .korean: return "ko"
            case .arabic: return "ar"
            case .hebrew: return "he"
            case .persian: return "fa"
            case .vietnamese: return "vi"
            case .indonesian: return "id"
            }
        }

        /// Native language name for the picker (not localized).
        var displayName: String {
            switch self {
            case .system: return "" // use L("system.language.system")
            case .english: return "English"
            case .russian: return "Русский"
            case .german: return "Deutsch"
            case .french: return "Français"
            case .spanish: return "Español"
            case .portugueseBrazil: return "Português"
            case .italian: return "Italiano"
            case .dutch: return "Nederlands"
            case .polish: return "Polski"
            case .czech: return "Čeština"
            case .romanian: return "Română"
            case .turkish: return "Türkçe"
            case .ukrainian: return "Українська"
            case .japanese: return "日本語"
            case .chineseSimplified: return "中文"
            case .korean: return "한국어"
            case .arabic: return "العربية"
            case .hebrew: return "עברית"
            case .persian: return "فارسی"
            case .vietnamese: return "Tiếng Việt"
            case .indonesian: return "Bahasa Indonesia"
            }
        }
    }

    private static let storageKey = "appLanguage.preference"

    @Published private(set) var preference: Preference

    /// Locale for SwiftUI / formatters. System uses macOS preferred language (not the process cache).
    var locale: Locale {
        if let code = preference.languageCode {
            return Locale(identifier: code)
        }
        if let systemID = Self.systemLanguageCodes.first {
            return Locale(identifier: systemID)
        }
        return Locale(identifier: Self.preferredCatalogCode())
    }

    /// Stable id to force SwiftUI view refresh when language changes.
    var refreshID: String { preference.rawValue }

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

    private func apply() {
        if let code = preference.languageCode {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
            AppLocale.languageCode = code
            AppLocale.current = Locale(identifier: code)
        } else {
            // Drop the override so the *next* launch follows macOS. This process
            // keeps the old AppleLanguages cache, so strings still load via an
            // explicit .lproj from Apple's preferredLocalizations matcher.
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            let code = Self.preferredCatalogCode()
            AppLocale.languageCode = code
            AppLocale.current = locale
        }

        LocalizationBundle.refresh()
        DurationFormat.setLocale(locale)
        objectWillChange.send()
    }

    /// System UI languages, ignoring this app’s `AppleLanguages` override.
    private static var systemLanguageCodes: [String] {
        let global = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        if let languages = global?["AppleLanguages"] as? [String], !languages.isEmpty {
            return languages
        }
        return Locale.preferredLanguages
    }

    /// Catalog code Apple would pick for the current macOS language list.
    private static func preferredCatalogCode() -> String {
        let available = Bundle.main.localizations.filter { $0 != "Base" }
        let preferred = systemLanguageCodes
        return Bundle.preferredLocalizations(from: available, forPreferences: preferred).first ?? "en"
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
        // Try exact code (e.g. pt-BR), then language-only (pt).
        let candidates = [code, code.split(separator: "-").first.map(String.init)].compactMap { $0 }
        for candidate in candidates {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                cachedBundle = bundle
                cachedCode = code
                return bundle
            }
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
