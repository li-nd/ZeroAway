import Foundation

enum SessionEndReason: String, Codable, Equatable {
    case manual
    case timer
    case quit
}

enum StatsRetention: Int, CaseIterable, Identifiable, Codable {
    case oneMonth = 1
    case threeMonths = 3
    case sixMonths = 6
    case oneYear = 12

    var id: Int { rawValue }

    var months: Int { rawValue }

    var label: String {
        switch self {
        case .oneMonth: return L("stats.retention.1_month")
        case .threeMonths: return L("stats.retention.3_months")
        case .sixMonths: return L("stats.retention.6_months")
        case .oneYear: return L("stats.retention.1_year")
        }
    }
}

enum StatsChartPeriod: Int, CaseIterable, Identifiable {
    case days7 = 7
    case days30 = 30
    case days90 = 90
    case days180 = 180

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .days7: return L("stats.period.7d")
        case .days30: return L("stats.period.1m")
        case .days90: return L("stats.period.3m")
        case .days180: return L("stats.period.6m")
        }
    }
}

struct UsageSessionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    /// Matches `SessionDuration.rawValue`.
    let durationPreset: String
    var nudgeCount: Int
    /// Timestamps of individual nudges (for hourly breakdown). May be empty on legacy records.
    var nudgeTimes: [Date]
    var endReason: SessionEndReason?
    /// Seconds the session was "active" (screen unlocked). `nil` = legacy wall-clock only.
    var activeSeconds: Int?

    /// Prefer accumulated active time; fall back to wall-clock for legacy records.
    var elapsedSeconds: TimeInterval {
        if let activeSeconds {
            return Double(max(0, activeSeconds))
        }
        let end = endedAt ?? Date()
        return max(0, end.timeIntervalSince(startedAt))
    }

    var isOpen: Bool { endedAt == nil }

    enum CodingKeys: String, CodingKey {
        case id, startedAt, endedAt, durationPreset, nudgeCount, nudgeTimes, endReason, activeSeconds
    }

    init(
        id: UUID,
        startedAt: Date,
        endedAt: Date?,
        durationPreset: String,
        nudgeCount: Int,
        nudgeTimes: [Date] = [],
        endReason: SessionEndReason?,
        activeSeconds: Int? = 0
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationPreset = durationPreset
        self.nudgeCount = nudgeCount
        self.nudgeTimes = nudgeTimes
        self.endReason = endReason
        self.activeSeconds = activeSeconds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        startedAt = try c.decode(Date.self, forKey: .startedAt)
        endedAt = try c.decodeIfPresent(Date.self, forKey: .endedAt)
        durationPreset = try c.decode(String.self, forKey: .durationPreset)
        nudgeTimes = try c.decodeIfPresent([Date].self, forKey: .nudgeTimes) ?? []
        let storedCount = try c.decodeIfPresent(Int.self, forKey: .nudgeCount) ?? 0
        nudgeCount = max(storedCount, nudgeTimes.count)
        endReason = try c.decodeIfPresent(SessionEndReason.self, forKey: .endReason)
        activeSeconds = try c.decodeIfPresent(Int.self, forKey: .activeSeconds)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(startedAt, forKey: .startedAt)
        try c.encodeIfPresent(endedAt, forKey: .endedAt)
        try c.encode(durationPreset, forKey: .durationPreset)
        try c.encode(nudgeCount, forKey: .nudgeCount)
        try c.encode(nudgeTimes, forKey: .nudgeTimes)
        try c.encodeIfPresent(endReason, forKey: .endReason)
        try c.encodeIfPresent(activeSeconds, forKey: .activeSeconds)
    }
}

struct DayNudgePoint: Identifiable, Equatable {
    let day: Date
    let nudges: Int
    var id: Date { day }
}

struct HourNudgePoint: Identifiable, Equatable {
    /// Start of the hour.
    let hour: Date
    let hourOfDay: Int
    let nudges: Int
    var id: Date { hour }
}

struct StatsSnapshot: Equatable {
    var todayNudges: Int
    var todaySessions: Int
    var todayActiveSeconds: Int
    var liveNudges: Int?
    var liveElapsedSeconds: Int?
}
