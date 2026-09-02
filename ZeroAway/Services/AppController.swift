import AppKit
import Combine
import Foundation
import SwiftUI

/// Owns Active/Paused state, 1s tick, nudge self-check, timed sessions, and display assertion.
@MainActor
final class AppController: ObservableObject {
    static let shared = AppController()

    enum Mode: Equatable {
        case paused
        case activeAlways
        case activeTimed
    }

    enum AppStatus: Equatable {
        case setup
        case broken
        case paused
        case waiting
        case active
    }

    // MARK: Published

    @Published private(set) var mode: Mode = .paused
    /// Remaining active (unlocked) seconds for a timed session.
    @Published private(set) var timedRemainingSeconds: TimeInterval?
    @Published private(set) var idleSeconds: Int = 0
    @Published private(set) var isTrusted: Bool = AccessibilityService.isTrusted()
    @Published private(set) var isScreenLocked: Bool = ScreenLockMonitor.isLocked()
    @Published private(set) var nudgeBlocked: Bool = false
    @Published private(set) var lastNudgeDate: Date?

    @Published var duration: SessionDuration {
        didSet {
            UserDefaults.standard.set(duration.rawValue, forKey: Keys.duration)
            if isActive { activate() }
        }
    }

    @Published var idleThreshold: Int {
        didSet {
            let clamped = IdleThresholdSlider.snap(IdleThresholdSlider.clamp(idleThreshold))
            if clamped != idleThreshold {
                idleThreshold = clamped
                return
            }
            UserDefaults.standard.set(idleThreshold, forKey: Keys.idleThreshold)
        }
    }

    @Published var nudgeDistance: Int {
        didSet {
            let clamped = NudgeDistanceSlider.clamp(nudgeDistance)
            if clamped != nudgeDistance {
                nudgeDistance = clamped
                return
            }
            UserDefaults.standard.set(nudgeDistance, forKey: Keys.nudgeDistance)
        }
    }
    @Published var workSchedule: WorkSchedule {
        didSet {
            workSchedule.save()
            reconcilePowerAssertion()
        }
    }

    @Published var requirePresenceApp: Bool {
        didSet {
            UserDefaults.standard.set(requirePresenceApp, forKey: Keys.requirePresenceApp)
            reconcilePowerAssertion()
        }
    }

    /// When enabled, an active session is restored after quit / reboot (timed sessions keep remaining active time).
    @Published var resumeSessionOnLaunch: Bool {
        didSet {
            UserDefaults.standard.set(resumeSessionOnLaunch, forKey: Keys.resumeSessionOnLaunch)
        }
    }

    var isActive: Bool { mode != .paused }
    var isNotWorking: Bool { isActive && nudgeBlocked }

    var appStatus: AppStatus {
        if !isTrusted { return .setup }
        if isNotWorking { return .broken }
        if !isActive { return .paused }
        if isWaitingForScreenLock || isWaitingForSchedule || isWaitingForPresence { return .waiting }
        return .active
    }

    var isWaitingForScreenLock: Bool {
        isActive && isScreenLocked
    }

    var isWaitingForSchedule: Bool {
        guard isActive, !isScreenLocked, mode != .activeTimed, workSchedule.enabled else { return false }
        return !ScheduleEvaluator.isWithin(schedule: workSchedule)
    }

    var isWaitingForPresence: Bool {
        guard isActive, !isScreenLocked, requirePresenceApp, mode != .activeTimed else { return false }
        return !PresenceMonitor.shared.isAnyEnabledAppRunning
    }

    var scheduleStatusLine: String {
        ScheduleEvaluator.statusLine(schedule: workSchedule)
    }

    var progressToNudge: Double {
        guard idleThreshold > 0 else { return 0 }
        return min(1, Double(idleSeconds) / Double(idleThreshold))
    }

    var lastNudgeLine: String? {
        guard let lastNudgeDate else { return nil }
        let relative = DurationFormat.relative(from: lastNudgeDate)
        return L("status.last_activity \(relative)")
    }

    var remainingTimedSeconds: TimeInterval? {
        guard mode == .activeTimed, let remaining = timedRemainingSeconds else { return nil }
        return max(0, remaining)
    }

    // MARK: Private

    private enum Keys {
        static let duration = "durationChoice"
        static let idleThreshold = "idleThreshold"
        static let nudgeDistance = "nudgeDistance"
        static let requirePresenceApp = "requirePresenceApp"
        static let resumeSessionOnLaunch = "resumeSessionOnLaunch"
        static let sessionWasActive = "sessionWasActive"
        static let sessionTimerRemaining = "sessionTimerRemaining"
        /// Legacy absolute end date — migrated to remaining on restore.
        static let sessionTimerEnd = "sessionTimerEnd"
    }

    private let displayAssertion = DisplayAssertion()
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var lockObserver: NSObjectProtocol?
    private var unlockObserver: NSObjectProtocol?
    private var notifiedExpiry = false

    private var awaitingNudgeVerify = false
    private var idleAtNudge = 0
    private var nudgeFailureStreak = 0
    private var lastTimedPersist = Date.distantPast

    private init() {
        let raw = UserDefaults.standard.string(forKey: Keys.duration) ?? SessionDuration.always.rawValue
        duration = SessionDuration(rawValue: raw) ?? .always

        let storedThreshold = UserDefaults.standard.integer(forKey: Keys.idleThreshold)
        idleThreshold = IdleThresholdSlider.snap(
            IdleThresholdSlider.clamp(storedThreshold == 0 ? 60 : storedThreshold)
        )

        let storedDistance = UserDefaults.standard.integer(forKey: Keys.nudgeDistance)
        nudgeDistance = NudgeDistanceSlider.clamp(storedDistance == 0 ? 1 : storedDistance)

        workSchedule = WorkSchedule.load()
        requirePresenceApp = UserDefaults.standard.bool(forKey: Keys.requirePresenceApp)
        resumeSessionOnLaunch = UserDefaults.standard.object(forKey: Keys.resumeSessionOnLaunch) as? Bool ?? true

        mode = .paused
        timedRemainingSeconds = nil
        observeWake()
        observeScreenLock()
        startTicking()
        restoreSessionIfNeeded()
    }

    // MARK: Actions

    func toggle() {
        if isActive { pause() } else { activate() }
    }

    func activate(restoringRemaining: TimeInterval? = nil) {
        if let secs = duration.seconds {
            mode = .activeTimed
            timedRemainingSeconds = restoringRemaining ?? secs
        } else {
            mode = .activeAlways
            timedRemainingSeconds = nil
        }
        notifiedExpiry = false
        resetNudgeVerification()
        UsageStatsStore.shared.startSession(durationPreset: duration.rawValue)
        persistSessionState()
        reconcilePowerAssertion()
    }

    func pause(endReason: SessionEndReason = .manual) {
        UsageStatsStore.shared.endSession(reason: endReason)
        mode = .paused
        timedRemainingSeconds = nil
        resetNudgeVerification()
        persistSessionState()
        reconcilePowerAssertion()
    }

    func selectSession(_ choice: SessionChoice) {
        switch choice {
        case .off:
            pause()
        case .duration(let d):
            duration = d
            activate()
        }
    }

    var sessionChoice: SessionChoice {
        guard isActive else { return .off }
        return .duration(duration)
    }

    enum SessionChoice: Equatable {
        case off
        case duration(SessionDuration)
    }

    func openAccessibilitySettings() {
        AccessibilityService.openSettings()
    }

    func refreshTrustStatus() {
        isTrusted = AccessibilityService.isTrusted()
    }

    // MARK: Tick

    private func startTicking() {
        AccessibilityService.requestTrustIfNeeded()
        isTrusted = AccessibilityService.isTrusted()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        t.tolerance = 0.2
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    private func tick() {
        isTrusted = AccessibilityService.isTrusted()
        // Notifications are primary; probe keeps state honest after sleep/wake races.
        let locked = ScreenLockMonitor.isLocked()
        if locked != isScreenLocked {
            setScreenLocked(locked)
        }

        let currentIdle = Int(IdleMonitor.idleSeconds())
        idleSeconds = currentIdle
        PresenceMonitor.shared.refresh()

        verifyLastNudge()

        if isActive && !isScreenLocked {
            UsageStatsStore.shared.tickActiveSecond()
            if mode == .activeTimed {
                if expireTimedSessionIfNeeded() { return }
            }
        }

        reconcilePowerAssertion()

        guard shouldNudgeNow() else { return }
        if idleSeconds >= idleThreshold {
            idleAtNudge = idleSeconds
            CursorNudge.perform(distance: nudgeDistance)
            lastNudgeDate = Date()
            awaitingNudgeVerify = true
            UsageStatsStore.shared.recordNudge()
        }
    }

    private func verifyLastNudge() {
        guard awaitingNudgeVerify else { return }
        awaitingNudgeVerify = false
        if idleSeconds >= idleAtNudge {
            nudgeFailureStreak += 1
        } else {
            nudgeFailureStreak = 0
        }
        nudgeBlocked = nudgeFailureStreak >= 2
    }

    private func resetNudgeVerification() {
        awaitingNudgeVerify = false
        idleAtNudge = 0
        nudgeFailureStreak = 0
        nudgeBlocked = false
    }

    private func persistSessionState() {
        let defaults = UserDefaults.standard
        defaults.set(isActive, forKey: Keys.sessionWasActive)
        if let remaining = timedRemainingSeconds {
            defaults.set(remaining, forKey: Keys.sessionTimerRemaining)
        } else {
            defaults.removeObject(forKey: Keys.sessionTimerRemaining)
        }
        defaults.removeObject(forKey: Keys.sessionTimerEnd)
    }

    private func restoreSessionIfNeeded() {
        guard resumeSessionOnLaunch else { return }
        guard UserDefaults.standard.bool(forKey: Keys.sessionWasActive) else { return }

        if duration.seconds != nil {
            let defaults = UserDefaults.standard
            let remaining: TimeInterval
            if defaults.object(forKey: Keys.sessionTimerRemaining) != nil {
                remaining = defaults.double(forKey: Keys.sessionTimerRemaining)
            } else {
                // Legacy absolute end → convert to remaining active time.
                let rawEnd = defaults.double(forKey: Keys.sessionTimerEnd)
                guard rawEnd > 0 else {
                    persistSessionState()
                    return
                }
                remaining = Date(timeIntervalSince1970: rawEnd).timeIntervalSinceNow
            }
            guard remaining > 0 else {
                mode = .paused
                timedRemainingSeconds = nil
                persistSessionState()
                return
            }
            activate(restoringRemaining: remaining)
        } else {
            activate()
        }
    }

    @discardableResult
    private func expireTimedSessionIfNeeded() -> Bool {
        guard mode == .activeTimed, var remaining = timedRemainingSeconds else { return false }
        remaining -= 1
        timedRemainingSeconds = remaining
        let shouldPersist = remaining <= 0 || Date().timeIntervalSince(lastTimedPersist) >= 15
        if shouldPersist {
            persistSessionState()
            lastTimedPersist = Date()
        }
        guard remaining <= 0 else { return false }
        pause(endReason: .timer)
        if !notifiedExpiry {
            notifiedExpiry = true
            Task { await NotificationService.shared.notifySessionEnded() }
        }
        return true
    }

    private func shouldNudgeNow() -> Bool {
        guard isActive, isTrusted, !isScreenLocked else { return false }
        if mode == .activeTimed { return true }
        if workSchedule.enabled, !ScheduleEvaluator.isWithin(schedule: workSchedule) {
            return false
        }
        if requirePresenceApp, !PresenceMonitor.shared.isAnyEnabledAppRunning {
            return false
        }
        return true
    }

    private func reconcilePowerAssertion() {
        if shouldNudgeNow() {
            displayAssertion.hold()
        } else {
            displayAssertion.release()
        }
    }

    private func setScreenLocked(_ locked: Bool) {
        guard isScreenLocked != locked else { return }
        isScreenLocked = locked
        if locked {
            resetNudgeVerification()
        }
        persistSessionState()
        reconcilePowerAssertion()
    }

    private func observeWake() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.setScreenLocked(ScreenLockMonitor.isLocked())
            }
        }
    }

    private func observeScreenLock() {
        let center = DistributedNotificationCenter.default()
        lockObserver = center.addObserver(
            forName: ScreenLockMonitor.didLockNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.setScreenLocked(true) }
        }
        unlockObserver = center.addObserver(
            forName: ScreenLockMonitor.didUnlockNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.setScreenLocked(false) }
        }
    }

    deinit {
        timer?.invalidate()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        let center = DistributedNotificationCenter.default()
        if let lockObserver {
            center.removeObserver(lockObserver)
        }
        if let unlockObserver {
            center.removeObserver(unlockObserver)
        }
        displayAssertion.release()
    }
}
