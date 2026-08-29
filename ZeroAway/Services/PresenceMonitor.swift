import AppKit
import Combine
import Foundation

/// Tracks workplace apps whose presence can flip to Away when the system is idle.
@MainActor
final class PresenceMonitor: ObservableObject {
    static let shared = PresenceMonitor()

    struct RunningApp: Identifiable, Equatable {
        let id: String
        let name: String
        let symbol: String
    }

    @Published private(set) var apps: [PresenceApp] = []
    @Published private(set) var runningIDs: Set<String> = []

    private var workspaceObservers: [NSObjectProtocol] = []

    private init() {
        apps = PresenceApp.load()
        refresh()
        subscribeToWorkspaceEvents()
    }

    var enabledApps: [PresenceApp] {
        apps.filter(\.isEnabled)
    }

    var runningApps: [RunningApp] {
        apps.compactMap { app in
            guard app.isEnabled, runningIDs.contains(app.id) else { return nil }
            return RunningApp(id: app.id, name: app.name, symbol: app.symbol)
        }
    }

    var isAnyEnabledAppRunning: Bool {
        !runningApps.isEmpty
    }

    /// Status under the presence-gate toggle.
    var gateStatusLine: (isSatisfied: Bool, text: String)? {
        let running = runningApps
        if running.isEmpty {
            return (false, L("presence.gate.none"))
        }
        if running.count == 1 {
            let name = running[0].name
            return (true, L("presence.gate.one \(name)"))
        }
        let names = running.map(\.name).joined(separator: ", ")
        return (true, L("presence.gate.many \(names)"))
    }

    func isRunning(_ app: PresenceApp) -> Bool {
        runningIDs.contains(app.id)
    }

    func statusLine(running: Bool) -> String {
        running ? L("presence.running") : L("presence.not_running")
    }

    func refresh() {
        let bundleIDs = Set(
            NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier)
        )
        let nextRunning = Set(
            apps.filter { app in
                app.isEnabled && app.bundleIDs.contains(where: bundleIDs.contains)
            }.map(\.id)
        )
        if nextRunning != runningIDs {
            runningIDs = nextRunning
        }
    }

    func replaceApps(_ next: [PresenceApp]) {
        apps = next
        PresenceApp.save(next)
        refresh()
    }

    func upsert(_ app: PresenceApp) {
        var next = apps
        if let idx = next.firstIndex(where: { $0.id == app.id }) {
            next[idx] = app
        } else {
            next.append(app)
        }
        replaceApps(next)
    }

    func remove(id: String) {
        replaceApps(apps.filter { $0.id != id })
    }

    func resetBuiltInApp(id: String) {
        guard let factory = PresenceApp.builtIn.first(where: { $0.id == id }) else { return }
        upsert(factory)
    }

    private func subscribeToWorkspaceEvents() {
        let center = NSWorkspace.shared.notificationCenter
        let refresh: (Notification) -> Void = { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        workspaceObservers = [
            center.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main,
                using: refresh
            ),
            center.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: .main,
                using: refresh
            ),
        ]
    }

    deinit {
        let center = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers {
            center.removeObserver(observer)
        }
    }
}
