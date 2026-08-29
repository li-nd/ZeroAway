import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var controller: AppController
    @EnvironmentObject private var launchAtLogin: LaunchAtLoginService

    var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                if controller.isTrusted && !controller.isNotWorking {
                    mainBody
                } else if controller.isTrusted {
                    brokenBody
                } else {
                    permissionGate
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .frame(width: 320)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            statusIndicator

            VStack(alignment: .leading, spacing: 2) {
                Text(controller.statusTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                if !controller.statusSubtitle.isEmpty {
                    Text(controller.statusSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                headerIconButton(
                    systemName: "gearshape",
                    help: L("menubar.help_settings")
                ) {
                    openSettings()
                }

                headerIconButton(
                    systemName: "xmark",
                    help: L("menubar.help_quit")
                ) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(.bottom, 14)
    }

    private func headerIconButton(
        systemName: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .overlay {
                if controller.appStatus == .active {
                    Circle()
                        .stroke(statusColor.opacity(0.35), lineWidth: 4)
                        .scaleEffect(1.6)
                }
            }
            .frame(width: 14, height: 14)
            .accessibilityHidden(true)
    }

    private var statusColor: Color {
        switch controller.appStatus {
        case .active: return Color(red: 0.30, green: 0.78, blue: 0.47)
        case .waiting: return .orange
        case .paused: return Color.secondary.opacity(0.7)
        case .setup, .broken: return Color(red: 1.0, green: 0.72, blue: 0.20)
        }
    }

    // MARK: - Main

    private var mainBody: some View {
        VStack(spacing: 14) {
            IdleGaugeView()
            SessionModePicker()
            PresenceBadgesView()
        }
    }

    private var brokenBody: some View {
        VStack(spacing: 14) {
            calloutCard(
                symbol: "exclamationmark.triangle.fill",
                tint: Color(red: 1.0, green: 0.72, blue: 0.20),
                title: L("status.broken.title"),
                body: L("status.broken.subtitle")
            ) {
                Button {
                    controller.openAccessibilitySettings()
                } label: {
                    Text(L("menubar.recheck_accessibility"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button(L("system.check_again")) {
                    controller.refreshTrustStatus()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Permission

    private var permissionGate: some View {
        calloutCard(
            symbol: "hand.raised.fill",
            tint: Color(red: 1.0, green: 0.72, blue: 0.20),
            title: nil,
            body: L("menubar.need_accessibility.body")
        ) {
            Button {
                controller.openAccessibilitySettings()
            } label: {
                Text(L("system.open_settings_ellipsis"))
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(L("system.check_again")) {
                controller.refreshTrustStatus()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
    }

    private func calloutCard<Actions: View>(
        symbol: String,
        tint: Color,
        title: String?,
        body: String,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 64, height: 64)
                Circle()
                    .strokeBorder(tint.opacity(0.22), lineWidth: 1)
                    .frame(width: 64, height: 64)
                Image(systemName: symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(tint)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.top, 2)

            VStack(spacing: 6) {
                if let title {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .multilineTextAlignment(.center)
                }

                Text(body)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 260)
            }

            VStack(spacing: 8) {
                actions()
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
                )
        )
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
    }
}

// MARK: - Status-item right-click menu

struct MenuBarAppMenuCommands: View {
    var openSettings: () -> Void

    var body: some View {
        Button(L("common.settings_ellipsis")) {
            openSettings()
        }
        Divider()
        Button(L("common.quit")) {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

/// Status item label with the same Settings / Quit menu on right-click.
struct MenuBarStatusLabel: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var controller = AppController.shared
    @ObservedObject private var iconSettings = MenuBarIconSettings.shared

    var body: some View {
        labelImage
            .contextMenu {
                MenuBarAppMenuCommands(openSettings: openSettings)
            }
    }

    @ViewBuilder
    private var labelImage: some View {
        let style = iconSettings.resolvedStyle(for: controller.appStatus)
        if let image = MenuBarIconRenderer.image(for: style) {
            Image(nsImage: image)
        } else {
            Image(systemName: style.symbolName)
        }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
    }
}
