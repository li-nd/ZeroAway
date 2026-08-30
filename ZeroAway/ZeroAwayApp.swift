import SwiftUI

@main
struct ZeroAwayApp: App {
    @ObservedObject private var controller = AppController.shared
    @ObservedObject private var launchAtLogin = LaunchAtLoginService.shared
    @ObservedObject private var languageSettings = AppLanguageSettings.shared
    @ObservedObject private var usageStats = UsageStatsStore.shared

    init() {
        AppPaths.migrateLegacySupportIfNeeded()
        // Ensure language override is applied before the first localized string lookup.
        _ = AppLanguageSettings.shared
        HotkeyMonitor.shared.start()
        Task { await NotificationService.shared.requestPermission() }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(controller)
                .environmentObject(launchAtLogin)
                .environmentObject(languageSettings)
                .environmentObject(usageStats)
                .environment(\.locale, languageSettings.locale)
                .id(languageSettings.refreshID)
        } label: {
            MenuBarStatusLabel()
                .environment(\.locale, languageSettings.locale)
                .id(languageSettings.refreshID)
        }
        .menuBarExtraStyle(.window)

        Window("ZeroAway", id: "settings") {
            SettingsWindowView()
                .environmentObject(controller)
                .environmentObject(launchAtLogin)
                .environmentObject(languageSettings)
                .environmentObject(usageStats)
                .environment(\.locale, languageSettings.locale)
        }
        .defaultSize(width: 960, height: 700)
        .windowToolbarStyle(.unified)
    }
}
