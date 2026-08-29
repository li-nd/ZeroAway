import Combine
import SwiftUI

struct StatisticsSettingsPanel: View {
    @EnvironmentObject private var controller: AppController
    @ObservedObject private var stats = UsageStatsStore.shared
    @State private var chartPeriod: StatsChartPeriod = .days7
    @State private var focusedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var confirmClear = false
    @State private var tick = Date()

    private let tickTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var calendar: Calendar { .current }

    private var earliestAllowedDay: Date {
        let start = calendar.date(byAdding: .month, value: -stats.retention.months, to: tick) ?? tick
        return calendar.startOfDay(for: start)
    }

    private var latestAllowedDay: Date {
        calendar.startOfDay(for: tick)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(title: L("stats.title"), subtitle: L("stats.subtitle"))
                enableCard

                if stats.isEnabled {
                    todaySection
                    if stats.liveSession != nil {
                        liveSessionRow
                    }
                    StatisticsChartsView(
                        stats: stats,
                        chartPeriod: $chartPeriod,
                        focusedDay: $focusedDay,
                        tick: tick,
                        earliestAllowedDay: earliestAllowedDay,
                        latestAllowedDay: latestAllowedDay
                    )
                    StatisticsHistoryView(
                        stats: stats,
                        confirmClear: $confirmClear,
                        onSelectDay: { date in
                            let day = calendar.startOfDay(for: date)
                            focusedDay = min(max(day, earliestAllowedDay), latestAllowedDay)
                        }
                    )
                } else {
                    disabledEmptyState
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onReceive(tickTimer) { date in
            tick = date
            focusedDay = min(max(focusedDay, earliestAllowedDay), latestAllowedDay)
        }
        .onChange(of: stats.isEnabled) { _, enabled in
            if enabled {
                stats.attachToActiveSessionIfNeeded(
                    durationPreset: controller.duration.rawValue,
                    isActive: controller.isActive
                )
                focusedDay = latestAllowedDay
            }
        }
        .confirmationDialog(
            L("stats.clear.confirm_title"),
            isPresented: $confirmClear,
            titleVisibility: .visible
        ) {
            Button(L("stats.clear.confirm_action"), role: .destructive) {
                stats.clearAllHistory()
            }
            Button(L("common.cancel"), role: .cancel) {}
        } message: {
            Text(L("stats.clear.confirm_message"))
        }
    }

    private var enableCard: some View {
        SettingsCard {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("stats.collect"))
                        .font(.headline)
                    Text(L("stats.collect.caption"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("", isOn: $stats.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
    }

    private var disabledEmptyState: some View {
        SettingsCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L("stats.disabled.title"))
                        .font(.headline)
                    Text(L("stats.disabled.body"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Today

    private var todaySection: some View {
        let snap = stats.snapshot(now: tick)
        return VStack(alignment: .leading, spacing: 12) {
            Text(L("stats.today"))
                .font(.headline)

            HStack(spacing: 12) {
                kpiCard(
                    title: L("stats.kpi.nudges"),
                    value: "\(snap.todayNudges)",
                    symbol: "cursorarrow.click"
                )
                kpiCard(
                    title: L("stats.kpi.sessions"),
                    value: "\(snap.todaySessions)",
                    symbol: "play.circle"
                )
                kpiCard(
                    title: L("stats.kpi.active_time"),
                    value: DurationFormat.countdown(seconds: snap.todayActiveSeconds),
                    symbol: "clock"
                )
            }
        }
    }

    private var liveSessionRow: some View {
        let snap = stats.snapshot(now: tick)
        return HStack(spacing: 10) {
            Image(systemName: "bolt.circle.fill")
                .foregroundStyle(Color.accentColor)
            Text(L("stats.live.title"))
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 8)
            Text(
                L(
                    "stats.live.detail \(snap.liveNudges ?? 0) \(DurationFormat.countdown(seconds: snap.liveElapsedSeconds ?? 0))"
                )
            )
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(0.08))
        )
    }

    private func kpiCard(title: String, value: String, symbol: String) -> some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
                Text(value)
                    .font(.title2.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

}
