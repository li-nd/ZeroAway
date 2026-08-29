import AppKit
import SwiftUI

struct PresenceBadgesView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var controller: AppController
    @ObservedObject private var presence = PresenceMonitor.shared

    var body: some View {
        // Timed sessions ignore the presence gate — don't show waiting UI then.
        if controller.requirePresenceApp, controller.mode != .activeTimed {
            Button(action: openPresenceSettings) {
                HStack(spacing: 8) {
                    if presence.runningApps.isEmpty {
                        Image(systemName: "person.crop.circle.badge.clock")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text(L("menubar.presence.waiting"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        ForEach(presence.runningApps.prefix(3)) { app in
                            HStack(spacing: 5) {
                                PresenceAppIcon(
                                    appID: app.id,
                                    symbol: app.symbol,
                                    side: 14,
                                    symbolFont: .system(size: 10, weight: .semibold)
                                )
                                Text(app.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.primary.opacity(0.07))
                            )
                        }
                        if presence.runningApps.count > 3 {
                            Text("+\(presence.runningApps.count - 3)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, presence.runningApps.isEmpty ? 10 : 0)
                .padding(.vertical, presence.runningApps.isEmpty ? 8 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Group {
                        if presence.runningApps.isEmpty {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        }
                    }
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(L("menubar.presence.open_help"))
        }
    }

    private func openPresenceSettings() {
        NotificationCenter.default.post(
            name: .openSettingsSection,
            object: nil,
            userInfo: ["section": SettingsWindowView.Section.presence.rawValue]
        )
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
    }
}

extension Notification.Name {
    static let openSettingsSection = Notification.Name("ZeroAway.openSettingsSection")
}
