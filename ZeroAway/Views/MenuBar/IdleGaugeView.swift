import SwiftUI

struct IdleGaugeView: View {
    @EnvironmentObject private var controller: AppController

    private var accent: Color {
        switch controller.appStatus {
        case .active: return Color(red: 0.35, green: 0.62, blue: 0.98)
        case .waiting: return .orange.opacity(0.85)
        case .paused: return .secondary
        case .setup, .broken: return .yellow
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 6)
                    .frame(width: 108, height: 108)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        accent,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 108, height: 108)
                    .animation(.easeOut(duration: 0.35), value: ringProgress)

                VStack(spacing: 2) {
                    Text(centerValue)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.2), value: centerValue)

                    Text(centerLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            if let caption {
                Text(caption)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .modifier(OptionalMonospacedDigits(
                        enabled: !controller.isWaitingForScreenLock
                            && !controller.isWaitingForSchedule
                            && !controller.isWaitingForPresence
                    ))
            }
        }
        .padding(.vertical, 4)
    }

    /// When active: countdown to nudge. Otherwise: idle time.
    private var centerValue: String {
        if controller.appStatus == .active {
            return formatClock(untilNudgeSeconds)
        }
        return formatClock(controller.idleSeconds)
    }

    private var centerLabel: String {
        if controller.appStatus == .active {
            return L("menubar.until_label")
        }
        return L("menubar.idle_label")
    }

    private var caption: String? {
        if controller.isWaitingForScreenLock {
            return L("menubar.caption.screen_lock")
        }
        if controller.isWaitingForSchedule {
            return controller.scheduleStatusLine
        }
        if controller.isWaitingForPresence {
            return L("menubar.caption.start_presence")
        }
        // Active countdown is in the ring center; paused needs no extra line.
        return nil
    }

    private var untilNudgeSeconds: Int {
        max(0, controller.idleThreshold - controller.idleSeconds)
    }

    private var ringProgress: CGFloat {
        switch controller.appStatus {
        case .active:
            // Keep a faint arc so an idle-zero session still feels “alive”.
            return max(0.045, CGFloat(controller.progressToNudge))
        case .waiting, .paused, .setup, .broken:
            return 0
        }
    }

    private func formatClock(_ totalSeconds: Int) -> String {
        let s = max(0, totalSeconds)
        if s >= 3600 { return String(format: "%d:%02d", s / 3600, (s % 3600) / 60) }
        if s >= 60 { return String(format: "%d:%02d", s / 60, s % 60) }
        return "\(s)"
    }
}

private struct OptionalMonospacedDigits: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.monospacedDigit()
        } else {
            content
        }
    }
}
