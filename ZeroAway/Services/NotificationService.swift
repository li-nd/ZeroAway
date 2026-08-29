import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    private var permissionGranted = false

    func requestPermission() async {
        do {
            permissionGranted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            permissionGranted = false
        }
    }

    func notifySessionEnded() async {
        guard permissionGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = L("notifications.session_ended.title")
        content.body = L("notifications.session_ended.body")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
