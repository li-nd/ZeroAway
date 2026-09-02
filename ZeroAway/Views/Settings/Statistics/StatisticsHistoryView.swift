import SwiftUI

struct StatisticsHistoryView: View {
    @ObservedObject var stats: UsageStatsStore
    @Binding var confirmClear: Bool
    @Binding var focusedDay: Date
    let tick: Date
    let earliestAllowedDay: Date
    let latestAllowedDay: Date

    private static let sessionsPageSize = 15

    @State private var showAllSessions = false

    private var calendar: Calendar { .current }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            historySection
            dataManagementCard
        }
        .onChange(of: focusedDay) { _, _ in
            showAllSessions = false
        }
    }

    private var historySection: some View {
        let rows = sessionsForFocusedDay
        let visible = showAllSessions ? rows : Array(rows.prefix(Self.sessionsPageSize))
        let remaining = rows.count - visible.count

        return VStack(alignment: .leading, spacing: 12) {
            Text(L("stats.history.title"))
                .font(.headline)

            StatisticsDaySwitcher(
                focusedDay: $focusedDay,
                earliestDay: earliestAllowedDay,
                latestDay: latestAllowedDay,
                title: StatisticsDayTitle.title(for: focusedDay),
                subtitle: L("stats.history.day_sessions \(rows.count)")
            )

            SettingsCard {
                if rows.isEmpty {
                    Text(L("stats.history.empty_day"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        historyHeader
                        Divider().opacity(0.4)

                        ForEach(Array(visible.enumerated()), id: \.element.id) { index, row in
                            historyRow(row)
                            if index < visible.count - 1 || remaining > 0 {
                                Divider().opacity(0.25)
                            }
                        }

                        if remaining > 0 {
                            Button {
                                showAllSessions = true
                            } label: {
                                Text(L("stats.history.show_more \(remaining)"))
                                    .font(.caption.weight(.medium))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        }
    }

    private var dataManagementCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(L("stats.data.title"))
                    .font(.headline)

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("stats.retention"))
                            .font(.subheadline.weight(.medium))
                        Text(L("stats.retention.caption"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("", selection: $stats.retention) {
                        ForEach(StatsRetention.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(minWidth: 140)
                }

                Divider().opacity(0.45)

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("stats.clear"))
                            .font(.subheadline.weight(.medium))
                        Text(L("stats.clear.caption"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button(L("stats.clear.button"), role: .destructive) {
                        confirmClear = true
                    }
                    .disabled(!stats.hasHistory)
                    .controlSize(.regular)
                }
            }
        }
    }

    // MARK: - Shared bits

    private var historyHeader: some View {
        HStack(spacing: 12) {
            Text(L("stats.history.col.when"))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L("stats.history.col.duration"))
                .frame(width: 72, alignment: .leading)
            Text(L("stats.history.col.length"))
                .frame(width: 72, alignment: .trailing)
            Text(L("stats.history.col.nudges"))
                .frame(width: 64, alignment: .trailing)
            Text(L("stats.history.col.ended"))
                .frame(width: 88, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
    }

    private func historyRow(_ row: UsageSessionRecord) -> some View {
        let _ = tick
        let elapsed = Int(row.elapsedSeconds)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.startedAt, format: .dateTime.hour().minute())
                    .font(.subheadline)
                if row.isOpen {
                    Text(L("stats.history.in_progress"))
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(presetLabel(row.durationPreset))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            Text(DurationFormat.short(seconds: elapsed))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(row.isOpen ? Color.accentColor : .primary)
                .frame(width: 72, alignment: .trailing)

            Text("\(row.nudgeCount)")
                .font(.subheadline.monospacedDigit())
                .frame(width: 64, alignment: .trailing)

            Text(endReasonLabel(row))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .trailing)
        }
        .padding(.vertical, 10)
    }

    private var sessionsForFocusedDay: [UsageSessionRecord] {
        let day = calendar.startOfDay(for: focusedDay)
        return stats.historySessions()
            .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private func presetLabel(_ raw: String) -> String {
        SessionDuration(rawValue: raw)?.label ?? raw
    }

    private func endReasonLabel(_ row: UsageSessionRecord) -> String {
        if row.isOpen { return "—" }
        switch row.endReason {
        case .timer: return L("stats.end.timer")
        case .quit: return L("stats.end.quit")
        case .manual, .none: return L("stats.end.manual")
        }
    }
}
