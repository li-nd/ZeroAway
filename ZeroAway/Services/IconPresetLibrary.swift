import AppKit
import Combine
import Foundation

@MainActor
final class IconPresetLibrary: ObservableObject {
    static let shared = IconPresetLibrary()

    static let defaultCatalogIndexURL = URL(
        string: "https://zeroaway.developer.pm/presets-catalog/index.json"
    )!

    @Published private(set) var bundled: [IconPresetFile] = []
    @Published private(set) var user: [IconPresetFile] = []
    @Published private(set) var catalog: [IconPresetFile] = []
    @Published private(set) var isLoadingCatalog = false
    @Published private(set) var catalogError: String?

    /// Custom catalog index URL. Empty string means the built-in default.
    @Published var catalogURLString: String {
        didSet {
            let trimmed = catalogURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed != catalogURLString {
                catalogURLString = trimmed
                return
            }
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: Keys.catalogURL)
            } else {
                UserDefaults.standard.set(trimmed, forKey: Keys.catalogURL)
            }
        }
    }

    var usesCustomCatalogURL: Bool {
        !catalogURLString.isEmpty
            && catalogURLString != Self.defaultCatalogIndexURL.absoluteString
    }

    /// URL shown in the editor (always a concrete string, never empty).
    var displayCatalogURL: String {
        resolvedCatalogURL?.absoluteString ?? Self.defaultCatalogIndexURL.absoluteString
    }

    var resolvedCatalogURL: URL? {
        if catalogURLString.isEmpty {
            return Self.defaultCatalogIndexURL
        }
        return URL(string: catalogURLString)
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder = JSONDecoder()

    private enum Keys {
        static let catalogURL = "iconPresets.catalogURL"
    }

    private init() {
        AppPaths.migrateLegacySupportIfNeeded()
        catalogURLString = UserDefaults.standard.string(forKey: Keys.catalogURL) ?? ""
        reload()
    }

    func resetCatalogURL() {
        catalogURLString = ""
    }

    /// Saves a catalog URL. The default address clears the override.
    func applyCatalogURL(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme == "http" || url.scheme == "https" else {
            return false
        }
        if url.absoluteString == Self.defaultCatalogIndexURL.absoluteString {
            resetCatalogURL()
        } else {
            catalogURLString = trimmed
        }
        return true
    }

    var installedIDs: Set<String> {
        Set(bundled.map(\.id) + user.map(\.id))
    }

    func reload() {
        bundled = loadBundled()
        user = loadUser()
    }

    // MARK: - Apply

    func apply(_ preset: IconPresetFile) {
        MenuBarIconSettings.shared.applyStyles(preset.stylesDictionary)
    }

    func isActive(_ preset: IconPresetFile) -> Bool {
        MenuBarIconSettings.shared.styles == preset.stylesDictionary
    }

    // MARK: - User library

    func saveUser(_ preset: IconPresetFile) throws {
        guard preset.isValidForSave else {
            throw LibraryError.invalidPreset
        }
        let url = userDirectory().appendingPathComponent("\(preset.id).json")
        let data = try encoder.encode(preset)
        try data.write(to: url, options: .atomic)
        reload()
    }

    func deleteUser(id: String) throws {
        let wasActive = user.first(where: { $0.id == id }).map(isActive) ?? false
        let url = userDirectory().appendingPathComponent("\(id).json")
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        reload()
        if wasActive, user.isEmpty {
            MenuBarIconSettings.shared.applyStyles(MenuBarIconSettings.defaultStyles())
        }
    }

    func importFromURL(_ url: URL) throws -> IconPresetFile {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let preset = try decodeValidated(data)
        try saveUser(preset)
        return preset
    }

    func export(_ preset: IconPresetFile, to url: URL) throws {
        let data = try encoder.encode(preset)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Catalog

    func refreshCatalog() async {
        isLoadingCatalog = true
        catalogError = nil
        defer { isLoadingCatalog = false }

        do {
            guard let url = resolvedCatalogURL else {
                throw LibraryError.invalidCatalogURL
            }
            // Bypass URLCache and ask intermediaries not to serve a cached index.
            var request = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalCacheData,
                timeoutInterval: 30
            )
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("no-cache", forHTTPHeaderField: "Pragma")

            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw LibraryError.catalogHTTP(http.statusCode)
            }
            let list = try decoder.decode([IconPresetFile].self, from: data)
            catalog = list.filter(\.usesOnlyAllowedSymbols)
        } catch {
            catalog = []
            catalogError = error.localizedDescription
        }
    }

    func installFromCatalog(_ preset: IconPresetFile) throws {
        guard preset.usesOnlyAllowedSymbols else { throw LibraryError.invalidSymbols }
        try saveUser(preset)
    }

    func installAndApplyFromCatalog(_ preset: IconPresetFile) throws {
        try installFromCatalog(preset)
        apply(preset)
    }

    // MARK: - Private

    private func loadBundled() -> [IconPresetFile] {
        var urls: [URL] = []
        for sub in ["IconPresets", "Resources/IconPresets"] {
            if let found = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: sub) {
                urls.append(contentsOf: found)
            }
        }
        if urls.isEmpty {
            urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        }

        var seen = Set<String>()
        return urls.compactMap { url -> IconPresetFile? in
            guard let data = try? Data(contentsOf: url),
                  let preset = try? decoder.decode(IconPresetFile.self, from: data),
                  !preset.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  preset.usesOnlyAllowedSymbols,
                  seen.insert(preset.id).inserted else {
                return nil
            }
            return preset
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func loadUser() -> [IconPresetFile] {
        let dir = userDirectory()
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        )) ?? []
        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decodeValidated(Data(contentsOf: $0)) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func decodeValidated(_ data: Data) throws -> IconPresetFile {
        let preset = try decoder.decode(IconPresetFile.self, from: data)
        guard !preset.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LibraryError.invalidPreset
        }
        guard preset.usesOnlyAllowedSymbols else {
            throw LibraryError.invalidSymbols
        }
        return preset
    }

    private func userDirectory() -> URL {
        let dir = AppPaths.iconPresetsDirectory
        AppPaths.ensureDirectory(dir)
        return dir
    }

    enum LibraryError: LocalizedError {
        case invalidPreset
        case invalidSymbols
        case invalidCatalogURL
        case catalogHTTP(Int)

        var errorDescription: String? {
            switch self {
            case .invalidPreset:
                return L("errors.invalid_preset")
            case .invalidSymbols:
                return L("errors.invalid_symbols")
            case .invalidCatalogURL:
                return L("errors.invalid_catalog_url")
            case .catalogHTTP(let code):
                return L("errors.catalog_http \(code)")
            }
        }
    }
}
