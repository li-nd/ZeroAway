import SwiftUI

struct SettingsWindowView: View {
    @EnvironmentObject private var controller: AppController
    @EnvironmentObject private var launchAtLogin: LaunchAtLoginService
    @EnvironmentObject private var languageSettings: AppLanguageSettings
    @State private var section: Section? = .behavior
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    enum Section: String, CaseIterable, Identifiable, Hashable {
        case behavior, presence, schedule, statistics, icons, system, about
        var id: String { rawValue }
        var label: String {
            switch self {
            case .behavior: return L("settings.behavior")
            case .presence: return L("settings.presence")
            case .schedule: return L("settings.schedule")
            case .statistics: return L("settings.statistics")
            case .icons: return L("settings.icons")
            case .system: return L("settings.system")
            case .about: return L("settings.about")
            }
        }
        var symbol: String {
            switch self {
            case .behavior: return "slider.horizontal.3"
            case .presence: return "person.crop.circle.badge.checkmark"
            case .schedule: return "calendar"
            case .statistics: return "chart.bar.xaxis"
            case .icons: return "menubar.rectangle"
            case .system: return "gearshape"
            case .about: return "info.circle"
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $section)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            Group {
                if let section {
                    detailContent(for: section)
                } else {
                    ContentUnavailableView(
                        L("common.choose_section"),
                        systemImage: "sidebar.left",
                        description: Text(L("common.choose_section_hint"))
                    )
                }
            }
            .navigationTitle("")
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 960, minHeight: 700)
        .environment(\.locale, languageSettings.locale)
        .onReceive(NotificationCenter.default.publisher(for: .openSettingsSection)) { note in
            if let raw = note.userInfo?["section"] as? String,
               let target = Section(rawValue: raw) {
                section = target
            }
        }
    }

    @ViewBuilder
    private func detailContent(for section: Section) -> some View {
        switch section {
        case .behavior:
            BehaviorSettingsPanel()
        case .presence:
            PresenceAppsSettingsPanel()
        case .schedule:
            ScheduleSettingsPanel()
        case .statistics:
            StatisticsSettingsPanel()
        case .icons:
            IconSettingsPanel()
        case .system:
            SystemSettingsPanel()
        case .about:
            AboutSettingsPanel()
        }
    }
}

// MARK: - Sidebar

private struct SidebarView: View {
    @Binding var selection: SettingsWindowView.Section?

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(SettingsWindowView.Section.allCases) { item in
                    Label(item.label, systemImage: item.symbol)
                        .tag(item)
                }
            }
            .listStyle(.sidebar)
            .contentMargins(.top, 0, for: .scrollContent)
        }
        .navigationTitle("")
    }
}
