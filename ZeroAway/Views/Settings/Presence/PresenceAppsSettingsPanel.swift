import AppKit
import SwiftUI

struct PresenceAppsSettingsPanel: View {
    @EnvironmentObject private var controller: AppController
    @ObservedObject private var presence = PresenceMonitor.shared
    @State private var editingID: String?

    private var editingApp: PresenceApp? {
        guard let editingID else { return nil }
        return presence.apps.first(where: { $0.id == editingID })
    }

    var body: some View {
        Group {
            if let app = editingApp {
                PresenceAppEditorView(
                    app: app,
                    onChange: { presence.upsert($0) },
                    onBack: { editingID = nil },
                    onDelete: {
                        presence.remove(id: app.id)
                        editingID = nil
                    },
                    onResetBuiltIn: {
                        presence.resetBuiltInApp(id: app.id)
                    }
                )
            } else {
                presenceList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - List

    private var presenceList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(title: L("presence.title"), subtitle: L("presence.subtitle"))

                presenceModeCard

                if presence.apps.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(presence.apps.enumerated()), id: \.element.id) { index, app in
                            if index > 0 {
                                Divider().padding(.leading, 68)
                            }
                            appRow(app)
                        }
                    }
                    .background { SettingsCardBackground() }
                }

                Button {
                    let created = PresenceApp.newCustom()
                    presence.upsert(created)
                    editingID = created.id
                } label: {
                    Label(L("presence.add_app"), systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var presenceModeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("behavior.presence.title"))
                        .font(.headline)
                    Text(L("behavior.presence.caption_list"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("", isOn: $controller.requirePresenceApp)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if controller.requirePresenceApp, let status = presence.gateStatusLine {
                Label(status.text, systemImage: status.isSatisfied ? "checkmark.circle" : "info.circle")
                    .font(.caption)
                    .foregroundStyle(status.isSatisfied ? Color.green : Color.orange)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { SettingsCardBackground() }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text(L("presence.empty.title"))
                .font(.headline)
            Text(L("presence.empty.body"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { SettingsCardBackground() }
    }

    private func appRow(_ app: PresenceApp) -> some View {
        let running = presence.isRunning(app)

        return HStack(spacing: 14) {
            Button {
                editingID = app.id
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                app.catalogImageName != nil
                                    ? Color.primary.opacity(0.06)
                                    : (app.isEnabled ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.06))
                            )
                            .frame(width: 40, height: 40)
                        PresenceAppIcon(
                            app: app,
                            side: 22,
                            symbolFont: .system(size: 17, weight: .medium),
                            symbolColor: app.isEnabled ? Color.accentColor : .secondary
                        )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.headline)
                            .foregroundStyle(app.isEnabled ? .primary : .secondary)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(running ? Color.green : Color.primary.opacity(0.25))
                                .frame(width: 7, height: 7)
                            Text(presence.statusLine(running: running))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !app.isEnabled {
                                Text(L("presence.disabled_suffix"))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle("", isOn: enabledBinding(for: app))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func enabledBinding(for app: PresenceApp) -> Binding<Bool> {
        Binding(
            get: { presence.apps.first(where: { $0.id == app.id })?.isEnabled ?? app.isEnabled },
            set: { value in
                var updated = app
                updated.isEnabled = value
                presence.upsert(updated)
            }
        )
    }
}

