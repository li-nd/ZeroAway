import Foundation

struct DaySchedule: Codable, Equatable, Identifiable {
    var enabled: Bool
    var startMinute: Int
    var endMinute: Int

    var id: Int { weekday }

    /// 1 = Sunday … 7 = Saturday (`Calendar` weekday).
    let weekday: Int

    init(weekday: Int, enabled: Bool, startMinute: Int, endMinute: Int) {
        self.weekday = weekday
        self.enabled = enabled
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    static func defaultDay(weekday: Int, enabled: Bool) -> DaySchedule {
        DaySchedule(weekday: weekday, enabled: enabled, startMinute: 9 * 60, endMinute: 18 * 60)
    }
}

struct WorkSchedule: Codable, Equatable {
    var enabled: Bool
    /// When false, all enabled days share `unifiedStartMinute` / `unifiedEndMinute`.
    var perDayHours: Bool
    var unifiedStartMinute: Int
    var unifiedEndMinute: Int
    var days: [DaySchedule]

    static var `default`: WorkSchedule {
        WorkSchedule(
            enabled: false,
            perDayHours: false,
            unifiedStartMinute: 9 * 60,
            unifiedEndMinute: 18 * 60,
            days: (1...7).map { DaySchedule.defaultDay(weekday: $0, enabled: (2...6).contains($0)) }
        )
    }

    func day(for weekday: Int) -> DaySchedule? {
        days.first { $0.weekday == weekday }
    }

    mutating func setDay(_ day: DaySchedule) {
        guard let idx = days.firstIndex(where: { $0.weekday == day.weekday }) else { return }
        days[idx] = day
    }

    func effectiveWindow(for weekday: Int) -> (enabled: Bool, start: Int, end: Int)? {
        guard let day = day(for: weekday) else { return nil }
        guard day.enabled else { return (false, 0, 0) }
        if perDayHours {
            return (true, day.startMinute, day.endMinute)
        }
        return (true, unifiedStartMinute, unifiedEndMinute)
    }

    var enabledWeekdayLabels: String {
        let cal = Calendar.current
        let symbols = cal.shortWeekdaySymbols
        let names = days
            .filter(\.enabled)
            .sorted { $0.weekday < $1.weekday }
            .compactMap { d -> String? in
                let idx = d.weekday - 1
                guard symbols.indices.contains(idx) else { return nil }
                return symbols[idx].lowercased()
            }
        return names.joined(separator: ", ")
    }

    // MARK: Persistence

    private static let storageKey = "workSchedule.v2"

    static func load() -> WorkSchedule {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(WorkSchedule.self, from: data) {
            return decoded
        }
        return migrateLegacy()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private static func migrateLegacy() -> WorkSchedule {
        var schedule = WorkSchedule.default
        let ud = UserDefaults.standard
        if ud.object(forKey: "scheduleEnabled") != nil {
            schedule.enabled = ud.bool(forKey: "scheduleEnabled")
        }
        let startH = ud.object(forKey: "scheduleStartHour") as? Int ?? 9
        let endH = ud.object(forKey: "scheduleEndHour") as? Int ?? 18
        schedule.unifiedStartMinute = startH * 60
        schedule.unifiedEndMinute = endH * 60
        let weekdaysOnly = ud.object(forKey: "scheduleWeekdaysOnly") as? Bool ?? true
        for i in schedule.days.indices {
            let wd = schedule.days[i].weekday
            if weekdaysOnly {
                schedule.days[i].enabled = (2...6).contains(wd)
            } else {
                schedule.days[i].enabled = true
            }
            schedule.days[i].startMinute = schedule.unifiedStartMinute
            schedule.days[i].endMinute = schedule.unifiedEndMinute
        }
        return schedule
    }
}

extension DaySchedule {
    static func minuteLabel(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }
}
