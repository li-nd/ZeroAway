import Foundation

enum ScheduleEvaluator {
    enum WeekdayLabelStyle {
        case short
        case long
    }

    struct StatusSummary {
        let isWithinWindow: Bool
        let title: String
        let detail: String
        let warning: String?
    }

    static func weekdayLabel(
        _ weekday: Int,
        style: WeekdayLabelStyle = .short,
        calendar: Calendar = .current,
        locale: Locale? = nil
    ) -> String {
        var cal = calendar
        cal.locale = locale ?? AppLocale.current
        let symbols = style == .short ? cal.shortWeekdaySymbols : cal.weekdaySymbols
        let idx = weekday - 1
        guard symbols.indices.contains(idx) else { return "?" }
        return symbols[idx]
    }

    static func isWithin(now: Date = Date(), schedule: WorkSchedule, calendar: Calendar = .current) -> Bool {
        guard schedule.enabled else { return true }

        let comps = calendar.dateComponents([.hour, .minute, .weekday], from: now)
        guard let weekday = comps.weekday else { return false }
        guard let window = schedule.effectiveWindow(for: weekday), window.enabled else { return false }

        let minute = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        return isMinuteWithin(minute, start: window.start, end: window.end)
    }

    static func isMinuteWithin(_ minute: Int, start: Int, end: Int) -> Bool {
        if start <= end {
            return minute >= start && minute < end
        }
        return minute >= start || minute < end
    }

    struct NextWindow {
        let date: Date
        let weekday: Int
        let startMinute: Int
        let endMinute: Int
    }

    static func nextWindow(
        from now: Date = Date(),
        schedule: WorkSchedule,
        calendar: Calendar = .current
    ) -> NextWindow? {
        guard schedule.enabled else { return nil }

        let startOfNow = calendar.startOfDay(for: now)
        for dayOffset in 0..<8 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfNow) else { continue }
            let wd = calendar.component(.weekday, from: day)
            guard let window = schedule.effectiveWindow(for: wd), window.enabled else { continue }

            let startDate = startOfMinute(window.start, on: day, calendar: calendar)
            if startDate > now {
                return NextWindow(
                    date: startDate,
                    weekday: wd,
                    startMinute: window.start,
                    endMinute: window.end
                )
            }
        }
        return nil
    }

    static func statusSummary(
        now: Date = Date(),
        schedule: WorkSchedule,
        calendar: Calendar = .current
    ) -> StatusSummary {
        guard schedule.enabled else {
            return StatusSummary(
                isWithinWindow: true,
                title: L("schedule.summary.disabled.title"),
                detail: L("schedule.summary.disabled.detail"),
                warning: nil
            )
        }

        let enabledCount = schedule.days.filter(\.enabled).count
        if enabledCount == 0 {
            return StatusSummary(
                isWithinWindow: false,
                title: L("status.waiting.title"),
                detail: L("schedule.summary.no_days.detail"),
                warning: L("schedule.summary.no_days.warning")
            )
        }

        if isWithin(now: now, schedule: schedule, calendar: calendar) {
            let wd = calendar.component(.weekday, from: now)
            if let window = schedule.effectiveWindow(for: wd) {
                let range = "\(DaySchedule.minuteLabel(window.start))–\(DaySchedule.minuteLabel(window.end))"
                return StatusSummary(
                    isWithinWindow: true,
                    title: L("schedule.summary.active.title"),
                    detail: L("schedule.summary.active_today \(range)"),
                    warning: nil
                )
            }
            return StatusSummary(
                isWithinWindow: true,
                title: L("schedule.summary.active.title"),
                detail: L("schedule.summary.active.now"),
                warning: nil
            )
        }

        if let next = nextWindow(from: now, schedule: schedule, calendar: calendar) {
            let name = weekdayLabel(next.weekday, style: .long, calendar: calendar)
            let time = DaySchedule.minuteLabel(next.startMinute)

            if calendar.isDateInToday(next.date) {
                return StatusSummary(
                    isWithinWindow: false,
                    title: L("status.waiting.title"),
                    detail: L("schedule.summary.next_today \(time)"),
                    warning: nil
                )
            }
            return StatusSummary(
                isWithinWindow: false,
                title: L("status.waiting.title"),
                detail: L("schedule.summary.next_weekday \(name) \(time)"),
                warning: nil
            )
        }

        return StatusSummary(
            isWithinWindow: false,
            title: L("status.waiting.title"),
            detail: L("schedule.summary.no_next"),
            warning: nil
        )
    }

    static func statusLine(now: Date = Date(), schedule: WorkSchedule, calendar: Calendar = .current) -> String {
        let summary = statusSummary(now: now, schedule: schedule, calendar: calendar)
        if let warning = summary.warning {
            return "\(summary.title) · \(summary.detail) · \(warning)"
        }
        return "\(summary.title) · \(summary.detail)"
    }

    /// Compact line for Behavior gate toggle: active now or time until next window.
    static func gateStatusLine(
        now: Date = Date(),
        schedule: WorkSchedule,
        calendar: Calendar = .current
    ) -> (isActive: Bool, text: String)? {
        guard schedule.enabled else { return nil }

        if schedule.days.filter(\.enabled).isEmpty {
            return (false, L("schedule.gate.no_days"))
        }

        if isWithin(now: now, schedule: schedule, calendar: calendar) {
            let wd = calendar.component(.weekday, from: now)
            if let window = schedule.effectiveWindow(for: wd), window.enabled {
                let range = "\(DaySchedule.minuteLabel(window.start))–\(DaySchedule.minuteLabel(window.end))"
                return (true, L("schedule.gate.active \(range)"))
            }
            return (true, L("schedule.gate.active_plain"))
        }

        guard let next = nextWindow(from: now, schedule: schedule, calendar: calendar) else {
            return (false, L("schedule.gate.no_next"))
        }

        let seconds = max(0, Int(next.date.timeIntervalSince(now)))
        let until = DurationFormat.countdown(seconds: seconds)
        let start = DaySchedule.minuteLabel(next.startMinute)

        if calendar.isDateInToday(next.date) {
            return (false, L("schedule.gate.until_today \(start) \(until)"))
        }
        if calendar.isDateInTomorrow(next.date) {
            return (false, L("schedule.gate.until_tomorrow \(start) \(until)"))
        }
        let name = weekdayLabel(next.weekday, style: .long, calendar: calendar)
        return (false, L("schedule.gate.until_weekday \(name) \(start) \(until)"))
    }

    private static func startOfMinute(_ minute: Int, on day: Date, calendar: Calendar) -> Date {
        var comps = calendar.dateComponents([.year, .month, .day], from: day)
        comps.hour = minute / 60
        comps.minute = minute % 60
        return calendar.date(from: comps) ?? day
    }
}
