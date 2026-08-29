import SwiftUI

struct SymbolPreviewIcon: View {
    let style: MenuBarIconStyle
    let size: CGFloat
    var onLightBackground: Bool?

    private var fontSize: CGFloat {
        size * CGFloat(style.pointSize / 18)
    }

    private var foreground: Color {
        if style.useSystemColor {
            if let onLightBackground {
                return (onLightBackground ? Color.black : Color.white).opacity(style.opacity)
            }
            return Color.primary.opacity(style.opacity)
        }
        return style.swiftUIColor
    }

    var body: some View {
        Image(systemName: SFSymbolCatalog.resolved(style.symbolName, fallback: "circle.fill"))
            .font(.system(size: fontSize, weight: .medium))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(foreground)
            .frame(height: size)
    }
}

