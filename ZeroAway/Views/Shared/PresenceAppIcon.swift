import AppKit
import SwiftUI

/// Renders a presence app icon from the asset catalog when available, otherwise an SF Symbol.
struct PresenceAppIcon: View {
    let appID: String
    let symbol: String
    var side: CGFloat = 18
    var symbolFont: Font = .system(size: 14, weight: .medium)
    var foreground: Color = .primary

    init(
        app: PresenceApp,
        side: CGFloat = 18,
        symbolFont: Font = .system(size: 14, weight: .medium),
        symbolColor: Color? = nil
    ) {
        self.appID = app.id
        self.symbol = app.symbol
        self.side = side
        self.symbolFont = symbolFont
        self.foreground = symbolColor ?? .primary
    }

    init(
        appID: String,
        symbol: String,
        side: CGFloat = 18,
        symbolFont: Font = .system(size: 14, weight: .medium),
        symbolColor: Color? = nil
    ) {
        self.appID = appID
        self.symbol = symbol
        self.side = side
        self.symbolFont = symbolFont
        self.foreground = symbolColor ?? .primary
    }

    var body: some View {
        if let assetName = PresenceApp.catalogImageName(for: appID),
           let nsImage = NSImage(named: assetName) {
            Image(nsImage: templateImage(nsImage))
                .resizable()
                .interpolation(.high)
                .renderingMode(.template)
                .foregroundStyle(foreground)
                .scaledToFit()
                .frame(width: side, height: side)
        } else {
            Image(systemName: SFSymbolCatalog.resolved(symbol, fallback: "app.fill"))
                .font(symbolFont)
                .foregroundStyle(foreground)
                .frame(width: side, height: side)
        }
    }

    private func templateImage(_ image: NSImage) -> NSImage {
        let copy = image.copy() as? NSImage ?? image
        copy.isTemplate = true
        return copy
    }
}

extension PresenceApp {
    /// Asset catalog names for built-in messaging apps.
    static func catalogImageName(for id: String) -> String? {
        switch id {
        case "slack": return "PresenceSlack"
        case "teams": return "PresenceTeams"
        case "mattermost": return "PresenceMattermost"
        default: return nil
        }
    }

    var catalogImageName: String? {
        Self.catalogImageName(for: id)
    }
}
