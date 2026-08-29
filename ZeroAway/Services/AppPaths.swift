import Foundation

/// Shared Application Support paths and one-shot migration from MouseJiggler.
enum AppPaths {
    static let appSupportFolderName = "ZeroAway"
    static let legacyAppSupportFolderName = "MouseJiggler"

    static var applicationSupportRoot: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        return base
    }

    static var supportRoot: URL {
        applicationSupportRoot.appendingPathComponent(appSupportFolderName, isDirectory: true)
    }

    static var legacySupportRoot: URL {
        applicationSupportRoot.appendingPathComponent(legacyAppSupportFolderName, isDirectory: true)
    }

    static var iconPresetsDirectory: URL {
        supportRoot.appendingPathComponent("IconPresets", isDirectory: true)
    }

    static var usageStatsFile: URL {
        supportRoot.appendingPathComponent("usage-stats.json", isDirectory: false)
    }

    /// Copies legacy MouseJiggler support data into ZeroAway once, if the new folder is empty.
    static func migrateLegacySupportIfNeeded() {
        let fm = FileManager.default
        let legacy = legacySupportRoot
        let modern = supportRoot

        guard fm.fileExists(atPath: legacy.path) else {
            ensureDirectory(modern)
            return
        }

        let modernExists = fm.fileExists(atPath: modern.path)
        let modernIsEmpty: Bool = {
            guard modernExists else { return true }
            let items = (try? fm.contentsOfDirectory(atPath: modern.path)) ?? []
            return items.isEmpty
        }()

        guard modernIsEmpty else { return }

        do {
            if modernExists {
                try fm.removeItem(at: modern)
            }
            try fm.copyItem(at: legacy, to: modern)
        } catch {
            ensureDirectory(modern)
        }
    }

    static func ensureDirectory(_ url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
