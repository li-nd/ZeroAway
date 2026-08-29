import AppKit

enum MenuBarIconRenderer {
    /// Typical menu-bar slot height; width follows symbol aspect ratio.
    static let menuBarHeight: CGFloat = 18
    static let maxMenuBarWidth: CGFloat = 28

    /// How to ink template / system-color glyphs.
    enum Tint {
        /// Real menu bar — template image, OS picks black/white.
        case menuBar
        /// Settings preview on light strip.
        case lightBackground
        /// Settings preview on dark strip / dark UI.
        case darkBackground
    }

    static func image(
        for style: MenuBarIconStyle,
        renderHeight: CGFloat? = nil,
        tint: Tint = .menuBar
    ) -> NSImage? {
        let name = SFSymbolCatalog.resolved(style.symbolName, fallback: "circle.fill")
        guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return nil }

        let height = renderHeight ?? CGFloat(style.pointSize)
        let config = NSImage.SymbolConfiguration(pointSize: height, weight: .medium)
        guard let symbol = base.withSymbolConfiguration(config) else { return nil }

        let natural = symbol.size
        guard natural.width > 0, natural.height > 0 else { return nil }

        let scale = height / natural.height
        var width = natural.width * scale
        if width > maxMenuBarWidth {
            width = maxMenuBarWidth
        }
        let canvas = NSSize(width: width, height: height)

        let drawScale = min(width / natural.width, height / natural.height)
        let drawW = natural.width * drawScale
        let drawH = natural.height * drawScale
        let rect = NSRect(
            x: (width - drawW) / 2,
            y: (height - drawH) / 2,
            width: drawW,
            height: drawH
        )

        let out = NSImage(size: canvas)
        out.lockFocus()

        if style.useSystemColor {
            switch tint {
            case .menuBar:
                symbol.draw(in: rect, from: .zero, operation: .sourceOver, fraction: style.opacity)
                out.isTemplate = true
            case .lightBackground, .darkBackground:
                let ink: NSColor = tint == .lightBackground ? .black : .white
                let color = ink.withAlphaComponent(style.opacity)
                let colored = symbol.withSymbolConfiguration(
                    NSImage.SymbolConfiguration(paletteColors: [color])
                ) ?? symbol
                colored.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
                out.isTemplate = false
            }
        } else {
            let colored = symbol.withSymbolConfiguration(
                NSImage.SymbolConfiguration(paletteColors: [style.nsColor])
            ) ?? symbol
            colored.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            out.isTemplate = false
        }

        out.unlockFocus()
        out.size = canvas
        return out
    }
}
