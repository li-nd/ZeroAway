import AppKit
import Carbon
import SwiftUI

// MARK: - System

struct SystemSettingsPanel: View {
    @EnvironmentObject private var controller: AppController
    @EnvironmentObject private var launchAtLogin: LaunchAtLoginService
    @EnvironmentObject private var languageSettings: AppLanguageSettings
    @ObservedObject private var hotkeys = HotkeyMonitor.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(title: L("system.title"), subtitle: L("system.subtitle"))

                SettingsCard {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("system.language"))
                                .font(.headline)
                            Text(L("system.language.caption"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Picker(
                            "",
                            selection: Binding(
                                get: { languageSettings.preference },
                                set: { languageSettings.setPreference($0) }
                            )
                        ) {
                            Text(L("system.language.system"))
                                .tag(AppLanguageSettings.Preference.system)
                            Text("English")
                                .tag(AppLanguageSettings.Preference.english)
                            Text("Русский")
                                .tag(AppLanguageSettings.Preference.russian)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(minWidth: 140)
                    }
                }

                SettingsCard {
                    trailingToggle(isOn: $launchAtLogin.isEnabled) {
                        Text(L("system.launch_at_login"))
                            .font(.headline)
                        Text(L("system.launch_at_login.caption"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SettingsCard {
                    trailingToggle(
                        isOn: Binding(
                            get: { hotkeys.isEnabled },
                            set: { hotkeys.setEnabled($0) }
                        )
                    ) {
                        Text(L("system.hotkey"))
                            .font(.headline)
                        Text(
                            hotkeys.isEnabled
                                ? L("system.hotkey.caption_on")
                                : L("system.hotkey.caption_off")
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    if hotkeys.isEnabled {
                        Divider().opacity(0.5)

                        HStack(spacing: 12) {
                            Text(L("system.combination"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 8)
                            HotkeyRecorderButton()
                            if hotkeys.shortcut != .default {
                                Button(L("common.reset")) {
                                    hotkeys.resetToDefault()
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                            }
                        }
                    }
                }

                accessibilityCard
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func trailingToggle<Label: View>(
        isOn: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                label()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }

    private var accessibilityCard: some View {
        let trusted = controller.isTrusted
        return SettingsCard {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: trusted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(trusted ? Color.green : Color.orange)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 8) {
                    Text(trusted ? L("system.accessibility.ok") : L("system.accessibility.needed"))
                        .font(.headline)
                    Text(
                        trusted
                            ? L("system.accessibility.ok_body")
                            : L("system.accessibility.needed_body")
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Button(L("system.open_settings_ellipsis")) {
                            controller.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button(L("system.check_again")) {
                            controller.refreshTrustStatus()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

}

// MARK: - Hotkey recorder

private struct HotkeyRecorderButton: View {
    @ObservedObject private var hotkeys = HotkeyMonitor.shared
    @State private var isRecording = false
    @State private var eventMonitor: Any?
    @State private var hint: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                Text(isRecording ? L("system.press_keys") : hotkeys.shortcut.displayString)
                    .font(.system(.body, design: .monospaced).weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isRecording ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                isRecording ? Color.accentColor.opacity(0.7) : Color.primary.opacity(0.12),
                                lineWidth: 1
                            )
                    )
            }
            .buttonStyle(.plain)
            .buttonStyle(.plain)
            .help(L("system.hotkey.help"))

            if let hint {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        stopRecording()
        isRecording = true
        hint = nil
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                Task { @MainActor in stopRecording() }
                return nil
            }
            if let shortcut = HotkeyShortcut.from(event: event) {
                Task { @MainActor in
                    hotkeys.update(shortcut)
                    stopRecording()
                }
                return nil
            }
            Task { @MainActor in
                hint = L("system.hotkey.need_modifier")
            }
            return nil
        }
    }

    private func stopRecording() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        isRecording = false
        hint = nil
    }
}
