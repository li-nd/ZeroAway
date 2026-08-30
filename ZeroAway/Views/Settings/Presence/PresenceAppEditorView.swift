import AppKit
import SwiftUI

struct PresenceAppEditorView: View {
    let app: PresenceApp
    let onChange: (PresenceApp) -> Void
    let onBack: () -> Void
    let onDelete: () -> Void
    let onResetBuiltIn: () -> Void

    @State private var draft: PresenceApp
    @State private var showRunningPicker = false
    @State private var manualBundleID = ""

    init(
        app: PresenceApp,
        onChange: @escaping (PresenceApp) -> Void,
        onBack: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onResetBuiltIn: @escaping () -> Void
    ) {
        self.app = app
        self.onChange = onChange
        self.onBack = onBack
        self.onDelete = onDelete
        self.onResetBuiltIn = onResetBuiltIn
        _draft = State(initialValue: app)
    }

    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            Divider()
            if app.isBuiltIn {
                ScrollView {
                    formColumn
                        .padding(24)
                        .frame(maxWidth: 520, alignment: .leading)
                }
            } else {
                HStack(alignment: .top, spacing: 0) {
                    ScrollView {
                        formColumn
                            .padding(24)
                    }
                    .frame(width: 340)

                    Divider()

                    SymbolCatalogPicker(selection: symbolBinding)
                        .padding(24)
                }
            }
        }
        .onChange(of: app) { _, newValue in
            if newValue.id == draft.id, newValue != draft {
                draft = newValue
            }
        }
        .sheet(isPresented: $showRunningPicker) {
            RunningAppsPickerSheet { bundleID, name, _ in
                addBundleID(bundleID)
                if !app.isBuiltIn, draft.name == L("presence.default_app_name"), !name.isEmpty {
                    draft.name = name
                    commit()
                }
            }
        }
    }

    private var editorToolbar: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Label(L("settings.presence"), systemImage: "chevron.backward")
            }
            .buttonStyle(.borderless)

            Spacer()

            statusBadge

            if app.isBuiltIn {
                Button(L("presence.reset_bundle_ids")) {
                    onResetBuiltIn()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help(L("presence.reset_bundle_ids_help"))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var statusBadge: some View {
        let running = PresenceMonitor.shared.isRunning(draft)
        return HStack(spacing: 6) {
            Circle()
                .fill(running ? Color.green : Color.primary.opacity(0.25))
                .frame(width: 7, height: 7)
            Text(PresenceMonitor.shared.statusLine(running: running))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.primary.opacity(0.06)))
    }

    private var formColumn: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            draft.catalogImageName != nil
                                ? Color.primary.opacity(0.06)
                                : Color.accentColor.opacity(0.14)
                        )
                        .frame(width: 56, height: 56)
                    PresenceAppIcon(
                        app: draft,
                        side: 32,
                        symbolFont: .system(size: 24, weight: .medium),
                        symbolColor: Color.accentColor
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    if app.isBuiltIn {
                        Text(draft.name)
                            .font(.title3.weight(.semibold))
                    } else {
                        TextField(L("presence.name_placeholder"), text: nameBinding)
                            .textFieldStyle(.roundedBorder)
                            .font(.headline)
                        Text(L("presence.custom_badge"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Toggle(L("presence.track"), isOn: enabledBinding)
                .toggleStyle(.switch)

            bundleSection

            if !app.isBuiltIn {
                Divider()
                Button(role: .destructive, action: onDelete) {
                    Label(L("presence.delete_app"), systemImage: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bundleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("presence.bundle_id.heading"))
                .font(.subheadline.weight(.semibold))

            Text(L("presence.bundle_id.caption"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showRunningPicker = true
            } label: {
                Label(L("presence.pick_running"), systemImage: "plus.app")
            }
            .buttonStyle(.bordered)

            if draft.bundleIDs.isEmpty {
                Text(L("presence.no_bundle_ids"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                VStack(spacing: 6) {
                    ForEach(draft.bundleIDs, id: \.self) { id in
                        HStack(spacing: 8) {
                            Text(id)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer(minLength: 4)
                            Button {
                                draft.bundleIDs.removeAll { $0 == id }
                                commit()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        )
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("com.example.app", text: $manualBundleID)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
                    .onSubmit(addManualBundleID)

                Button(L("common.add")) {
                    addManualBundleID()
                }
                .disabled(manualBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { SettingsCardBackground() }
    }

    // MARK: - Bindings & helpers

    private var nameBinding: Binding<String> {
        Binding(
            get: { draft.name },
            set: {
                draft.name = $0
                commit()
            }
        )
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { draft.isEnabled },
            set: {
                draft.isEnabled = $0
                commit()
            }
        )
    }

    private var symbolBinding: Binding<String> {
        Binding(
            get: { draft.symbol },
            set: {
                draft.symbol = $0
                commit()
            }
        )
    }

    private func addBundleID(_ id: String) {
        let trimmed = id.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !draft.bundleIDs.contains(trimmed) else { return }
        draft.bundleIDs.append(trimmed)
        commit()
    }

    private func addManualBundleID() {
        addBundleID(manualBundleID)
        manualBundleID = ""
    }

    private func commit() {
        var cleaned = draft
        if app.isBuiltIn, let factory = PresenceApp.builtIn.first(where: { $0.id == app.id }) {
            cleaned.name = factory.name
            cleaned.symbol = factory.symbol
        } else {
            cleaned.name = cleaned.name.trimmingCharacters(in: .whitespaces)
            if cleaned.name.isEmpty { cleaned.name = L("presence.default_app_name") }
        }
        cleaned.bundleIDs = cleaned.bundleIDs
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        draft = cleaned
        onChange(cleaned)
    }
}

