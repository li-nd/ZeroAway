import AppKit
import Combine
import Foundation

/// Local-only usage history: sessions and nudge counts.
@MainActor
final class UsageStatsStore: ObservableObject {
    static let shared = UsageStatsStore()

    @Published private(set) var sessions: [UsageSessionRecord] = []
    @Published private(set) var liveSession: UsageSessionRecord?

    @Published var isEnabled: Bool {
        didSet {
            guard isBootstrapped, isEnabled != oldValue else { return }
            UserDefaults.standard.set(isEnabled, forKey: Keys.enabled)
            if isEnabled {
                // Caller should reconcile with an active session via `attachToActiveSessionIfNeeded`.
            } else {
                endSession(reason: .manual)
            }
        }
    }

    @Published var retention: StatsRetention {
        didSet {
            guard isBootstrapped, retention != oldValue else { return }
            UserDefaults.standard.set(retention.rawValue, forKey: Keys.retention)
            pruneExpired()
            persist()
        }
    }

    var hasHistory: Bool {
        !sessions.isEmpty || liveSession != nil
    }

    private var isBootstrapped = false
    private var terminateObserver: NSObjectProtocol?
    private var saveWorkItem: DispatchWorkItem?

    private init() {
        AppPaths.migrateLegacySupportIfNeeded()
        isEnabled = UserDefaults.standard.bool(forKey: Keys.enabled)
        let storedRetention = UserDefaults.standard.integer(forKey: Keys.retention)
        retention = StatsRetention(rawValue: storedRetention == 0 ? StatsRetention.sixMonths.rawValue : storedRetention)
            ?? .sixMonths

        let loaded = Self.loadPayload()
        sessions = loaded.sessions.sorted { $0.startedAt > $1.startedAt }
        // Orphan open session from a previous launch → close as quit.
        if var orphan = loaded.liveSession {
            orphan.endedAt = Date()
            orphan.endReason = .quit
            sessions.insert(orphan, at: 0)
        }

        pruneExpired()
        persist()
        isBootstrapped = true

        terminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.endSession(reason: .quit)
            }
        }
    }

    deinit {
        if let terminateObserver {
            NotificationCenter.default.removeObserver(terminateObserver)
        }
    }

    // MARK: - Session lifecycle

    /// Start tracking if enabled. Ends any previous live session first.
    func startSession(durationPreset: String) {
        guard isEnabled else { return }
        if liveSession != nil {
            endSession(reason: .manual)
        }
        liveSession = UsageSessionRecord(
            id: UUID(),
            startedAt: Date(),
            endedAt: nil,
            durationPreset: durationPreset,
            nudgeCount: 0,
            nudgeTimes: [],
            endReason: nil
        )
        persistSoon()
    }

    /// If stats were just enabled while a session is already running.
    func attachToActiveSessionIfNeeded(durationPreset: String, isActive: Bool) {
        guard isEnabled, isActive, liveSession == nil else { return }
        startSession(durationPreset: durationPreset)
    }

    func endSession(reason: SessionEndReason) {
        guard var live = liveSession else { return }
        live.endedAt = Date()
        live.endReason = reason
        liveSession = nil
        sessions.insert(live, at: 0)
        pruneExpired()
        persist()
    }

    func recordNudge(at date: Date = Date()) {
        guard isEnabled, var live = liveSession else { return }
        live.nudgeTimes.append(date)
        live.nudgeCount = live.nudgeTimes.count
        liveSession = live
        persistSoon()
    }

    func clearAllHistory() {
        let resumePreset = liveSession?.durationPreset
        let resume = isEnabled && liveSession != nil
        sessions = []
        liveSession = nil
        persist()
        if resume, let resumePreset {
            startSession(durationPreset: resumePreset)
        }
    }

    // MARK: - Queries

    func snapshot(now: Date = Date()) -> StatsSnapshot {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: now)

        var nudges = 0
        var sessionCount = 0
        var activeSeconds = 0

        for session in sessions where session.startedAt >= startOfDay {
            sessionCount += 1
            nudges += session.nudgeCount
            activeSeconds += Int(session.elapsedSeconds)
        }

        var liveNudges: Int?
        var liveElapsed: Int?

        if let live = liveSession {
            liveNudges = live.nudgeCount
            liveElapsed = Int(live.elapsedSeconds)
            if live.startedAt >= startOfDay {
                sessionCount += 1
                nudges += live.nudgeCount
                activeSeconds += Int(live.elapsedSeconds)
            } else {
                sessionCount += 1
                nudges += live.nudgeCount
                activeSeconds += Int(max(0, now.timeIntervalSince(startOfDay)))
            }
        }

        return StatsSnapshot(
            todayNudges: nudges,
            todaySessions: sessionCount,
            todayActiveSeconds: activeSeconds,
            liveNudges: liveNudges,
            liveElapsedSeconds: liveElapsed
        )
    }

    func dailyNudges(period: StatsChartPeriod, now: Date = Date()) -> [DayNudgePoint] {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        guard let rangeStart = cal.date(byAdding: .day, value: -(period.rawValue - 1), to: startOfToday) else {
            return []
        }

        var buckets: [Date: Int] = [:]
        for offset in 0..<period.rawValue {
            if let day = cal.date(byAdding: .day, value: offset, to: rangeStart) {
                buckets[cal.startOfDay(for: day)] = 0
            }
        }

        for time in nudgeTimes(from: rangeStart) {
            let day = cal.startOfDay(for: time)
            buckets[day, default: 0] += 1
        }

        // Legacy sessions without timestamps: attribute count to the session start day.
        for session in sessions where session.nudgeTimes.isEmpty && session.nudgeCount > 0 {
            let day = cal.startOfDay(for: session.startedAt)
            guard day >= rangeStart else { continue }
            buckets[day, default: 0] += session.nudgeCount
        }

        return buckets.keys.sorted().map { DayNudgePoint(day: $0, nudges: buckets[$0] ?? 0) }
    }

    /// 24 hourly buckets for a calendar day (local timezone).
    func hourlyNudges(on day: Date, now: Date = Date()) -> [HourNudgePoint] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }

        var buckets: [Int: Int] = [:]
        for hour in 0..<24 {
            buckets[hour] = 0
        }

        for time in nudgeTimes(from: start, to: end) {
            let hour = cal.component(.hour, from: time)
            buckets[hour, default: 0] += 1
        }

        // Don't show future hours for today as empty noise — still show them as 0 for a full day shape.
        _ = now

        return (0..<24).compactMap { hour -> HourNudgePoint? in
            guard let hourDate = cal.date(bySettingHour: hour, minute: 0, second: 0, of: start) else {
                return nil
            }
            return HourNudgePoint(hour: hourDate, hourOfDay: hour, nudges: buckets[hour] ?? 0)
        }
    }

    func historySessions() -> [UsageSessionRecord] {
        var items = sessions
        if let live = liveSession {
            items.insert(live, at: 0)
        }
        return items
    }

    // MARK: - Private

    private enum Keys {
        static let enabled = "usageStats.enabled"
        static let retention = "usageStats.retentionMonths"
    }

    private struct Payload: Codable {
        var sessions: [UsageSessionRecord]
        var liveSession: UsageSessionRecord?
    }

    private func nudgeTimes(from start: Date, to end: Date? = nil) -> [Date] {
        var times: [Date] = []
        for session in sessions {
            times.append(contentsOf: session.nudgeTimes)
        }
        if let live = liveSession {
            times.append(contentsOf: live.nudgeTimes)
        }
        return times.filter { time in
            time >= start && (end == nil || time < end!)
        }
    }

    private func pruneExpired() {
        guard let cutoff = Calendar.current.date(byAdding: .month, value: -retention.months, to: Date()) else {
            return
        }
        sessions.removeAll { $0.startedAt < cutoff }
    }

    private func persistSoon() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.persist() }
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    private func persist() {
        saveWorkItem?.cancel()
        saveWorkItem = nil
        let payload = Payload(sessions: sessions, liveSession: liveSession)
        do {
            let data = try JSONEncoder().encode(payload)
            try data.write(to: Self.fileURL(), options: .atomic)
        } catch {
            // Best-effort local store.
        }
    }

    private static func loadPayload() -> Payload {
        let url = fileURL()
        guard let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return Payload(sessions: [], liveSession: nil)
        }
        return payload
    }

    private static func fileURL() -> URL {
        AppPaths.ensureDirectory(AppPaths.supportRoot)
        return AppPaths.usageStatsFile
    }
}
