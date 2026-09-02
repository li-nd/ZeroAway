import CoreGraphics
import Foundation

/// Screen lock state via distributed notifications + session dictionary probe.
enum ScreenLockMonitor {
    static let didLockNotification = Notification.Name("com.apple.screenIsLocked")
    static let didUnlockNotification = Notification.Name("com.apple.screenIsUnlocked")

    /// Best-effort current lock flag (undocumented session key).
    static func isLocked() -> Bool {
        guard let cfDict = CGSessionCopyCurrentDictionary() else { return false }
        let dict = cfDict as NSDictionary
        if let number = dict["CGSSessionScreenIsLocked"] as? NSNumber {
            return number.boolValue
        }
        if let flag = dict["CGSSessionScreenIsLocked"] as? Bool {
            return flag
        }
        return false
    }
}
