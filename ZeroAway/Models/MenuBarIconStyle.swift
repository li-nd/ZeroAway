import AppKit
import SwiftUI

struct MenuBarIconStyle: Codable, Equatable {
    var symbolName: String
    var useSystemColor: Bool
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    var pointSize: Double

    static func `default`(symbol: String, opacity: Double = 1, system: Bool = true) -> MenuBarIconStyle {
        MenuBarIconStyle(
            symbolName: symbol,
            useSystemColor: system,
            red: 1, green: 1, blue: 1,
            opacity: opacity,
            pointSize: 18
        )
    }

    static var alertDefault: MenuBarIconStyle {
        MenuBarIconStyle(
            symbolName: "exclamationmark.triangle.fill",
            useSystemColor: false,
            red: 0.95, green: 0.72, blue: 0.18,
            opacity: 1,
            pointSize: 18
        )
    }

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: opacity)
    }

    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

enum MenuBarIconRole: String, CaseIterable, Identifiable, Codable {
    case active, paused, waiting, alert

    var id: String { rawValue }

    var label: String {
        switch self {
        case .active: return L("icons.role.active")
        case .paused: return L("icons.role.paused")
        case .waiting: return L("icons.role.waiting")
        case .alert: return L("icons.role.alert")
        }
    }
}
