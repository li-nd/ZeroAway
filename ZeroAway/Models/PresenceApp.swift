import Foundation

struct PresenceApp: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var symbol: String
    var bundleIDs: [String]
    var isEnabled: Bool
    let isBuiltIn: Bool

    static let builtIn: [PresenceApp] = [
        PresenceApp(
            id: "slack",
            name: "Slack",
            symbol: "number",
            bundleIDs: ["com.tinyspeck.slackmacgap"],
            isEnabled: true,
            isBuiltIn: true
        ),
        PresenceApp(
            id: "teams",
            name: "Teams",
            symbol: "person.2.fill",
            bundleIDs: ["com.microsoft.teams", "com.microsoft.teams2"],
            isEnabled: true,
            isBuiltIn: true
        ),
        PresenceApp(
            id: "mattermost",
            name: "Mattermost",
            symbol: "bubble.left.and.bubble.right.fill",
            bundleIDs: ["Mattermost.Desktop", "com.mattermost.desktop"],
            isEnabled: true,
            isBuiltIn: true
        ),
    ]

    /// Built-in IDs retired from the default list (stripped on load).
    private static let retiredBuiltInIDs: Set<String> = ["webex", "ringcentral"]

    static func newCustom(name: String = L("presence.default_app_name"), bundleID: String = "") -> PresenceApp {
        PresenceApp(
            id: UUID().uuidString,
            name: name,
            symbol: "app.fill",
            bundleIDs: bundleID.isEmpty ? [] : [bundleID],
            isEnabled: true,
            isBuiltIn: false
        )
    }

    // MARK: Persistence

    private static let storageKey = "presenceApps.v1"

    static func load() -> [PresenceApp] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PresenceApp].self, from: data),
              !decoded.isEmpty else {
            return builtIn
        }
        let pruned = decoded.filter { !retiredBuiltInIDs.contains($0.id) }
        if pruned.count != decoded.count {
            save(pruned.isEmpty ? builtIn : pruned)
        }
        return pruned.isEmpty ? builtIn : pruned
    }

    static func save(_ apps: [PresenceApp]) {
        if let data = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
