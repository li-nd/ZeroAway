import Foundation

extension AppController {
    var statusTitle: String {
        switch appStatus {
        case .setup: return L("status.setup.title")
        case .broken: return L("status.broken.title")
        case .paused: return L("status.paused.title")
        case .waiting: return L("status.waiting.title")
        case .active: return L("status.active.title")
        }
    }

    var statusSubtitle: String {
        switch appStatus {
        case .setup:
            return L("status.setup.subtitle")
        case .broken:
            return L("status.broken.subtitle")
        case .paused:
            return L("status.paused.subtitle")
        case .waiting:
            if isWaitingForSchedule { return L("status.waiting.schedule") }
            if isWaitingForPresence { return L("status.waiting.presence") }
            return L("status.waiting.title")
        case .active:
            if let remaining = remainingTimedSeconds {
                let clock = DurationFormat.countdown(seconds: Int(remaining))
                return L("status.active.session_remaining \(clock)")
            }
            return duration.sessionLabel
        }
    }

    var menuBarTooltip: String {
        switch appStatus {
        case .setup: return L("status.tooltip.setup")
        case .broken: return L("status.tooltip.broken")
        case .paused:
            let idle = DurationFormat.short(seconds: idleSeconds)
            return L("status.tooltip.paused \(idle)")
        case .waiting:
            if isWaitingForSchedule { return L("status.tooltip.waiting_schedule") }
            if isWaitingForPresence { return L("status.tooltip.waiting_presence") }
            return L("status.tooltip.waiting")
        case .active:
            let idle = DurationFormat.short(seconds: idleSeconds)
            let threshold = DurationFormat.short(seconds: idleThreshold)
            return L("status.tooltip.active \(idle) \(threshold)")
        }
    }
}
