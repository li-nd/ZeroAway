import AppKit
import SwiftUI

struct AboutSettingsPanel: View {
    private static let repositoryURL = URL(string: "https://github.com/li-nd/ZeroAway")!
    private static let documentationURL = URL(string: "https://zeroaway.developer.pm/")!

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String? {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(title: L("about.title"), subtitle: L("about.subtitle"))

                SettingsCard {
                    HStack(alignment: .top, spacing: 16) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            Text("ZeroAway")
                                .font(.title3.weight(.semibold))
                            Text(versionLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(L("about.blurb"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                        }
                    }
                }

                SettingsCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L("about.author"))
                            .font(.headline)
                        Text("Markus Lind")
                            .font(.body)

                        Divider().opacity(0.5)

                        linkRow(
                            title: L("about.repository"),
                            subtitle: L("about.repository.caption"),
                            url: Self.repositoryURL,
                            systemImage: "chevron.left.forwardslash.chevron.right"
                        )
                        linkRow(
                            title: L("about.website"),
                            subtitle: L("about.website.caption"),
                            url: Self.documentationURL,
                            systemImage: "globe"
                        )
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var versionLabel: String {
        if let buildNumber, buildNumber != appVersion {
            return L("about.version_build \(appVersion) \(buildNumber)")
        }
        return L("about.version \(appVersion)")
    }

    private func linkRow(
        title: String,
        subtitle: String? = nil,
        url: URL,
        systemImage: String
    ) -> some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}
