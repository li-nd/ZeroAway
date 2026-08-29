import SwiftUI

/// Shared settings card chrome (12pt continuous corner, subtle fill + stroke).
struct SettingsCard<Content: View>: View {
    var spacing: CGFloat = 12
    var padding: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { SettingsCardBackground() }
    }
}

/// Card with independent horizontal / vertical padding (e.g. Behavior stacked sections).
struct SettingsPaddedCard<Content: View>: View {
    var horizontal: CGFloat = 20
    var vertical: CGFloat = 8
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { SettingsCardBackground() }
    }
}

struct SettingsCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.primary.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}
