import SwiftUI

struct WorkScheduleEditorView: View {
    @Binding var schedule: WorkSchedule
    private let calendar = Calendar.current

    /// Fixed time slots (15-minute grid) — lightweight vs DatePicker.
    private static let slotStep = 15
    private static let timeSlots: [Int] = Array(stride(from: 0, through: 24 * 60 - slotStep, by: slotStep))

    private enum WorkMode: String, CaseIterable, Identifiable {
        case always
        case scheduled

        var id: String { rawValue }

        var label: String {
            switch self {
            case .always: return L("schedule.mode.always")
            case .scheduled: return L("schedule.mode.scheduled")
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            SettingsPageHeader(title: L("schedule.title"), subtitle: L("schedule.subtitle"))

            modePicker

            if schedule.enabled {
                scheduledContent
            } else {
                alwaysModeContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header

    // MARK: - Mode

    private var modePicker: some View {
        Picker("", selection: modeBinding) {
            ForEach(WorkMode.allCases) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var modeBinding: Binding<WorkMode> {
        Binding(
            get: { schedule.enabled ? .scheduled : .always },
            set: { schedule.enabled = $0 == .scheduled }
        )
    }

    // MARK: - Always

    private var alwaysModeContent: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "infinity")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 8) {
                Text(L("schedule.always.title"))
                    .font(.headline)
                Text(L("schedule.always.body"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { SettingsCardBackground() }
    }

    // MARK: - Scheduled

    private var scheduledContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScheduleStatusCard(schedule: schedule)

            settingsSection

            timedSessionHint
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L("schedule.settings"))
                .font(.headline)

            Picker("", selection: $schedule.perDayHours) {
                Text(L("schedule.time.unified")).tag(false)
                Text(L("schedule.time.per_day")).tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: schedule.perDayHours) { _, perDay in
                if perDay { syncUnifiedToDays() }
            }

            if schedule.perDayHours {
                perDayList
            } else {
                unifiedDayPicker
                unifiedTimeRow
            }

            if schedule.days.filter(\.enabled).isEmpty {
                Label(L("schedule.pick_workday"), systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { SettingsCardBackground() }
    }

    private var timedSessionHint: some View {
        Label {
            Text(L("schedule.timed_hint"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "info.circle")
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Unified

    private var unifiedDayPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("schedule.workdays"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(orderedWeekdays, id: \.self) { wd in
                    dayChip(weekday: wd) {
                        toggleDay(wd)
                    }
                }
            }
        }
    }

    private var unifiedTimeRow: some View {
        HStack(spacing: 20) {
            minuteSlotPicker(L("schedule.from"), binding: $schedule.unifiedStartMinute)
            minuteSlotPicker(L("schedule.to"), binding: $schedule.unifiedEndMinute)
        }
    }

    // MARK: - Per day

    private var perDayList: some View {
        VStack(spacing: 10) {
            ForEach(orderedWeekdays, id: \.self) { wd in
                if let idx = schedule.days.firstIndex(where: { $0.weekday == wd }) {
                    perDayRow(binding: $schedule.days[idx])
                }
            }
        }
    }

    private func perDayRow(binding: Binding<DaySchedule>) -> some View {
        HStack(spacing: 12) {
            Toggle(isOn: binding.enabled) {
                Text(weekdayName(binding.wrappedValue.weekday))
                    .frame(width: 36, alignment: .leading)
            }
            .toggleStyle(.checkbox)

            if binding.wrappedValue.enabled {
                minuteSlotPicker(L("schedule.from_lower"), binding: Binding(
                    get: { binding.wrappedValue.startMinute },
                    set: { binding.wrappedValue.startMinute = $0 }
                ))
                Text("–").foregroundStyle(.secondary)
                minuteSlotPicker(L("schedule.to"), binding: Binding(
                    get: { binding.wrappedValue.endMinute },
                    set: { binding.wrappedValue.endMinute = $0 }
                ))

                Button(L("schedule.copy_to_all")) {
                    copyDayToAll(binding.wrappedValue)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            } else {
                Text(L("schedule.day_off"))
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Helpers

    private var orderedWeekdays: [Int] {
        let first = calendar.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    private func weekdayName(_ wd: Int) -> String {
        ScheduleEvaluator.weekdayLabel(wd, style: .short, calendar: calendar)
    }

    private func dayChip(weekday: Int, action: @escaping () -> Void) -> some View {
        let enabled = schedule.day(for: weekday)?.enabled ?? false
        return Button(action: action) {
            Text(weekdayName(weekday))
                .font(.system(size: 12, weight: enabled ? .semibold : .regular))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(enabled ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(enabled ? Color.accentColor.opacity(0.5) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func toggleDay(_ weekday: Int) {
        guard let idx = schedule.days.firstIndex(where: { $0.weekday == weekday }) else { return }
        var updated = schedule
        updated.days[idx].enabled.toggle()
        schedule = updated
    }

    private func syncUnifiedToDays() {
        var updated = schedule
        for i in updated.days.indices {
            updated.days[i].startMinute = Self.snapped(updated.unifiedStartMinute)
            updated.days[i].endMinute = Self.snapped(updated.unifiedEndMinute)
        }
        schedule = updated
    }

    private func copyDayToAll(_ source: DaySchedule) {
        var updated = schedule
        for i in updated.days.indices where updated.days[i].enabled {
            updated.days[i].startMinute = Self.snapped(source.startMinute)
            updated.days[i].endMinute = Self.snapped(source.endMinute)
        }
        schedule = updated
    }

    private func minuteSlotPicker(_ label: String, binding: Binding<Int>) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Picker(label, selection: snappedBinding(binding)) {
                ForEach(Self.timeSlots, id: \.self) { minute in
                    Text(DaySchedule.minuteLabel(minute)).tag(minute)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()
        }
    }

    private func snappedBinding(_ binding: Binding<Int>) -> Binding<Int> {
        Binding(
            get: { Self.snapped(binding.wrappedValue) },
            set: { binding.wrappedValue = Self.snapped($0) }
        )
    }

    private static func snapped(_ minute: Int) -> Int {
        let clamped = min(max(minute, 0), 24 * 60 - slotStep)
        let rounded = Int((Double(clamped) / Double(slotStep)).rounded()) * slotStep
        return min(max(rounded, 0), 24 * 60 - slotStep)
    }
}

// MARK: - Status card

private struct ScheduleStatusCard: View {
    let schedule: WorkSchedule
    private let summary: ScheduleEvaluator.StatusSummary

    init(schedule: WorkSchedule) {
        self.schedule = schedule
        self.summary = ScheduleEvaluator.statusSummary(schedule: schedule)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: summary.isWithinWindow ? "checkmark.circle.fill" : "pause.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(summary.isWithinWindow ? Color.green : Color.orange)

            VStack(alignment: .leading, spacing: 6) {
                Text(summary.title)
                    .font(.headline)
                Text(summary.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let warning = summary.warning {
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { SettingsCardBackground() }
    }
}
