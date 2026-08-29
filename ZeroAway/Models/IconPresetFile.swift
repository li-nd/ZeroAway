import Foundation

struct IconPresetRoleStyle: Codable, Equatable {
    var symbol: String
    var systemColor: Bool
    var color: [Double]?
    var opacity: Double
    var pointSize: Double

    func toMenuBarStyle() -> MenuBarIconStyle {
        var red = 1.0, green = 1.0, blue = 1.0
        if let color, color.count >= 3 {
            red = color[0]
            green = color[1]
            blue = color[2]
        }
        return MenuBarIconStyle(
            symbolName: symbol,
            useSystemColor: systemColor,
            red: red,
            green: green,
            blue: blue,
            opacity: opacity,
            pointSize: pointSize
        )
    }

    static func from(_ style: MenuBarIconStyle) -> IconPresetRoleStyle {
        IconPresetRoleStyle(
            symbol: style.symbolName,
            systemColor: style.useSystemColor,
            color: style.useSystemColor ? nil : [style.red, style.green, style.blue],
            opacity: style.opacity,
            pointSize: style.pointSize
        )
    }
}

struct IconPresetFile: Codable, Equatable, Identifiable {
    var id: String
    var author: String?
    /// English display name.
    var name: String
    var roles: Roles

    struct Roles: Codable, Equatable {
        var active: IconPresetRoleStyle
        var paused: IconPresetRoleStyle
        var waiting: IconPresetRoleStyle
        var alert: IconPresetRoleStyle

        subscript(role: MenuBarIconRole) -> IconPresetRoleStyle {
            get {
                switch role {
                case .active: return active
                case .paused: return paused
                case .waiting: return waiting
                case .alert: return alert
                }
            }
            set {
                switch role {
                case .active: active = newValue
                case .paused: paused = newValue
                case .waiting: waiting = newValue
                case .alert: alert = newValue
                }
            }
        }
    }

    var stylesDictionary: [MenuBarIconRole: MenuBarIconStyle] {
        [
            .active: roles.active.toMenuBarStyle(),
            .paused: roles.paused.toMenuBarStyle(),
            .waiting: roles.waiting.toMenuBarStyle(),
            .alert: roles.alert.toMenuBarStyle(),
        ]
    }

    var allSymbols: [String] {
        [roles.active.symbol, roles.paused.symbol, roles.waiting.symbol, roles.alert.symbol]
    }

    var usesOnlyAllowedSymbols: Bool {
        let allowed = Set(SFSymbolCatalog.available)
        return allSymbols.allSatisfy { allowed.contains($0) }
    }

    var isValidForSave: Bool {
        !id.isEmpty
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && usesOnlyAllowedSymbols
    }

    static func fromCurrentStyles(
        id: String = UUID().uuidString,
        name: String,
        author: String? = nil,
        styles: [MenuBarIconRole: MenuBarIconStyle]
    ) -> IconPresetFile {
        IconPresetFile(
            id: id,
            author: author.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 },
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            roles: Roles(
                active: .from(styles[.active] ?? .default(symbol: "circle.fill")),
                paused: .from(styles[.paused] ?? .default(symbol: "circle.fill")),
                waiting: .from(styles[.waiting] ?? .default(symbol: "circle.fill")),
                alert: .from(styles[.alert] ?? .alertDefault)
            )
        )
    }

    func duplicated() -> IconPresetFile {
        var copy = self
        copy.id = UUID().uuidString
        copy.name = "\(name) Copy"
        return copy
    }
}
