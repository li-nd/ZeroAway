import CoreGraphics
import Foundation

/// Posts a net-zero mouseMoved pair to reset the HID idle counter.
enum CursorNudge {
    static func perform(distance: Int = 1) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let origin = CGEvent(source: nil)?.location ?? .zero
        let bumped = bumpedPoint(from: origin, distance: distance)

        CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: bumped,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)

        CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: origin,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    /// Prefer +X; fall back to other axes if the offset would leave active displays.
    private static func bumpedPoint(from origin: CGPoint, distance: Int) -> CGPoint {
        let d = CGFloat(NudgeDistanceSlider.clamp(distance))
        let candidates: [(CGFloat, CGFloat)] = [(d, 0), (-d, 0), (0, d), (0, -d)]
        for (dx, dy) in candidates {
            let point = CGPoint(x: origin.x + dx, y: origin.y + dy)
            if canMove(to: point) {
                return point
            }
        }
        let fallback: CGFloat = canMove(to: CGPoint(x: origin.x + 1, y: origin.y)) ? 1 : -1
        return CGPoint(x: origin.x + fallback, y: origin.y)
    }

    private static func canMove(to point: CGPoint) -> Bool {
        var displayCount: UInt32 = 32
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        guard CGGetActiveDisplayList(displayCount, &displays, &displayCount) == .success else {
            return CGDisplayBounds(CGMainDisplayID()).contains(point)
        }
        for i in 0..<Int(displayCount) {
            if CGDisplayBounds(displays[i]).contains(point) {
                return true
            }
        }
        return false
    }
}
