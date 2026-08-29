import AppKit
import Carbon
import Combine
import Foundation

/// Global hotkey toggle via Carbon RegisterEventHotKey (no SPM dependency).
@MainActor
final class HotkeyMonitor: ObservableObject {
    static let shared = HotkeyMonitor()

    @Published private(set) var shortcut: HotkeyShortcut
    @Published private(set) var isEnabled: Bool

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotKeyID = EventHotKeyID(signature: OSType(0x4D4A474C), id: 1) // 'MJGL'
    private static let storageKey = "hotkeySettings.v2"
    private static let legacyKey = "hotkeyShortcut.v1"

    private struct Storage: Codable {
        var isEnabled: Bool
        var shortcut: HotkeyShortcut
    }

    private init() {
        if let stored = Self.load() {
            shortcut = stored.shortcut
            isEnabled = stored.isEnabled
        } else {
            shortcut = .default
            isEnabled = true
        }
    }

    func start() {
        installHandlerIfNeeded()
        registerCurrent()
    }

    func stop() {
        unregisterHotKey()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        save()
        registerCurrent()
    }

    func update(_ newShortcut: HotkeyShortcut) {
        guard newShortcut.hasRequiredModifier else { return }
        guard newShortcut != shortcut || !isEnabled else { return }
        shortcut = newShortcut
        isEnabled = true
        save()
        registerCurrent()
    }

    func resetToDefault() {
        shortcut = .default
        isEnabled = true
        save()
        registerCurrent()
    }

    func clear() {
        isEnabled = false
        save()
        registerCurrent()
    }

    // MARK: - Registration

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let event else { return noErr }
                var hkID = EventHotKeyID()
                let paramStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                guard paramStatus == noErr, hkID.signature == OSType(0x4D4A474C) else {
                    return paramStatus == noErr ? noErr : paramStatus
                }
                Task { @MainActor in
                    guard HotkeyMonitor.shared.isEnabled else { return }
                    AppController.shared.toggle()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        if status != noErr {
            eventHandler = nil
        }
    }

    private func registerCurrent() {
        unregisterHotKey()
        guard isEnabled else { return }

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRef = ref
        } else {
            hotKeyRef = nil
        }
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    // MARK: - Persistence

    private func save() {
        let blob = Storage(isEnabled: isEnabled, shortcut: shortcut)
        if let data = try? JSONEncoder().encode(blob) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private static func load() -> Storage? {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Storage.self, from: data),
           decoded.shortcut.hasRequiredModifier {
            return decoded
        }
        // Migrate v1 (shortcut only, always enabled).
        if let data = UserDefaults.standard.data(forKey: legacyKey),
           let shortcut = try? JSONDecoder().decode(HotkeyShortcut.self, from: data),
           shortcut.hasRequiredModifier {
            return Storage(isEnabled: true, shortcut: shortcut)
        }
        return nil
    }
}
