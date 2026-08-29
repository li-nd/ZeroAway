import SwiftUI

struct StatisticsHistoryView: View {
    @ObservedObject var stats: UsageStatsStore
    @Binding var confirmClear: Bool
    let onSelectDay: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            historySection
            dataManagementCard
        }
    }

    private var historySection: some View {
        let rows = stats.historySessions()
        return VStack(alignment: .leading, spacing: 12) {
            Text(L("stats.history.title"))
                .font(.headline)

            SettingsCard {
                if rows.isEmpty {
                    Text(L("stats.history.empty"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        historyHeader
                        Divider().opacity(0.4)
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            historyRow(row)
                                .contentShape(Rectangle())
                                .onTapGesture { onSelectDay(row.startedAt) }
                            if index < rows.count - 1 {
                                Divider().opacity(0.25)
                            }
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
                .frame(width: 88, alignment: .leading)
            Text(L("stats.history.col.nudges"))
                .frame(width: 72, alignment: .trailing)
            Text(L("stats.history.col.ended"))
                .frame(width: 100, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
    }

    private func historyRow(_ row: UsageSessionRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.startedAt, format: .dateTime.day().month(.abbreviated).hour().minute())
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
                .frame(width: 88, alignment: .leading)

            Text("\(row.nudgeCount)")
                .font(.subheadline.monospacedDigit())
                .frame(width: 72, alignment: .trailing)

            Text(endReasonLabel(row))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 10)
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
