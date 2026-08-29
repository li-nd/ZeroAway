import CoreGraphics
import Foundation

/// Reads system input-idle the same way Electron apps (Slack/Teams) do.
enum IdleMonitor {
    private static let inputTypes: [CGEventType] = [
        .mouseMoved,
        .leftMouseDown,
        .rightMouseDown,
        .otherMouseDown,
        .leftMouseDragged,
        .rightMouseDragged,
        .keyDown,
        .scrollWheel,
        .flagsChanged,
    ]

    /// Seconds since the most recent user input of any kind.
    static func idleSeconds() -> TimeInterval {
        inputTypes
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min() ?? 0
    }
}
