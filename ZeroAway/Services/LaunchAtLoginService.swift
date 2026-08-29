import Combine
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class LaunchAtLoginService: ObservableObject {
    static let shared = LaunchAtLoginService()

    @Published var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            updateSystemState(isEnabled)
        }
    }

    private init() {
        isEnabled = (SMAppService.mainApp.status == .enabled)
    }

    private func updateSystemState(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            isEnabled = !enabled
        }
    }
}
