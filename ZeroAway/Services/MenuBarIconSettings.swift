import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarIconSettings: ObservableObject {
    static let shared = MenuBarIconSettings()

    @Published private(set) var styles: [MenuBarIconRole: MenuBarIconStyle] {
        didSet { save() }
    }

    @Published var selectedRole: MenuBarIconRole = .active
    @Published var previewTheme: PreviewTheme = .light

    enum PreviewTheme: String, CaseIterable, Identifiable {
        case light, dark
        var id: String { rawValue }
        var label: String { self == .light ? L("icons.theme.light") : L("icons.theme.dark") }
    }

    private static let storageKey = "menuBarIconStyles.v3"
    private static let legacyKey = "menuBarIconStyles.v2"

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(Storage.self, from: data) {
            styles = decoded.styles
        } else if let legacy = Self.loadLegacy() {
            styles = legacy
        } else {
            styles = Self.defaultStyles()
        }
        syncPreviewThemeFromSystem()
        // NSApp is often still nil during early singleton init — retry on next run loop.
        if NSApp == nil {
            DispatchQueue.main.async { [weak self] in
                self?.syncPreviewThemeFromSystem()
            }
        }
        normalizeSymbols()
    }

    private func syncPreviewThemeFromSystem() {
        guard let app = NSApp else {
            previewTheme = .light
            return
        }
        let match = app.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua])
        previewTheme = match == .darkAqua ? .dark : .light
    }

    private struct Storage: Codable {
        var styles: [MenuBarIconRole: MenuBarIconStyle]
    }

    private struct LegacyStorage: Codable {
        var pausedMirrorsActive: Bool?
        var styles: [MenuBarIconRole: MenuBarIconStyle]
    }

    private static func loadLegacy() -> [MenuBarIconRole: MenuBarIconStyle]? {
        guard let data = UserDefaults.standard.data(forKey: legacyKey),
              let decoded = try? JSONDecoder().decode(LegacyStorage.self, from: data) else { return nil }
        return decoded.styles
    }

    private func save() {
        let blob = Storage(styles: styles)
        if let data = try? JSONEncoder().encode(blob) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
        objectWillChange.send()
    }

    static func defaultStyles() -> [MenuBarIconRole: MenuBarIconStyle] {
        [
            .active: .default(symbol: "computermouse.fill", opacity: 1),
            .paused: .default(symbol: "computermouse", opacity: 0.4),
            .waiting: .default(symbol: "clock", opacity: 0.55),
            .alert: .alertDefault,
        ]
    }

    func style(for role: MenuBarIconRole) -> MenuBarIconStyle {
        styles[role] ?? Self.defaultStyles()[role] ?? .default(symbol: "circle.fill")
    }

    func setStyle(_ style: MenuBarIconStyle, for role: MenuBarIconRole) {
        var copy = styles
        copy[role] = style
        styles = copy
    }

    func resolvedStyle(for status: AppController.AppStatus) -> MenuBarIconStyle {
        switch status {
        case .setup, .broken:
            return style(for: .alert)
        case .paused:
            return style(for: .paused)
        case .waiting:
            return style(for: .waiting)
        case .active:
            return style(for: .active)
        }
    }

    func applyPreset(_ preset: IconPresetFile) {
        styles = preset.stylesDictionary
    }

    func applyStyles(_ newStyles: [MenuBarIconRole: MenuBarIconStyle]) {
        styles = newStyles
    }

    func resetRole(_ role: MenuBarIconRole) {
        let defaults = Self.defaultStyles()
        setStyle(defaults[role] ?? .default(symbol: "circle.fill"), for: role)
    }

    func isRoleModified(_ role: MenuBarIconRole) -> Bool {
        let defaults = Self.defaultStyles()
        return style(for: role) != defaults[role]
    }

    private func normalizeSymbols() {
        for role in MenuBarIconRole.allCases {
            var s = style(for: role)
            s.symbolName = SFSymbolCatalog.resolved(s.symbolName, fallback: "computermouse.fill")
            setStyle(s, for: role)
        }
    }
}
