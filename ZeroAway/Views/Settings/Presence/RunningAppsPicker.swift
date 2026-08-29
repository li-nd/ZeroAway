import AppKit
import SwiftUI

struct RunningAppsPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String, String, NSImage?) -> Void

    private struct Item: Identifiable {
        let id: String
        let name: String
        let icon: NSImage?
    }

    private var running: [Item] {
        NSWorkspace.shared.runningApplications
            .compactMap { app -> Item? in
                guard let id = app.bundleIdentifier,
                      app.activationPolicy == .regular,
                      let name = app.localizedName else { return nil }
                return Item(id: id, name: name, icon: app.icon)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("presence.running_apps.title"))
                .font(.title3.weight(.semibold))

            Text(L("presence.running_apps.caption"))
                .font(.caption)
                .foregroundStyle(.secondary)

            List(running) { item in
                Button {
                    onSelect(item.id, item.name, item.icon)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        if let icon = item.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 28, height: 28)
                                .cornerRadius(6)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.primary.opacity(0.08))
                                .frame(width: 28, height: 28)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                            Text(item.id)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fontDesign(.monospaced)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            HStack {
                Spacer()
                Button(L("common.close")) { dismiss() }
            }
        }
        .padding(20)
        .frame(width: 440, height: 460)
    }
}
