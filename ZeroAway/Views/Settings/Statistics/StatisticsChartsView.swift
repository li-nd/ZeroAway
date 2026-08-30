import Charts
import SwiftUI

struct StatisticsChartsView: View {
    @ObservedObject var stats: UsageStatsStore
    @Binding var chartPeriod: StatsChartPeriod
    @Binding var focusedDay: Date
    let tick: Date
    let earliestAllowedDay: Date
    let latestAllowedDay: Date

    private var calendar: Calendar { .current }

    private var chartStride: Int {
        switch chartPeriod {
        case .days7: return 1
        case .days30: return 5
        case .days90: return 14
        }
    }

    var body: some View {
        let dayPoints = stats.dailyNudges(period: chartPeriod, now: tick)
        let periodTotal = dayPoints.reduce(0) { $0 + $1.nudges }
        let hourPoints = stats.hourlyNudges(on: focusedDay, now: tick)
        let dayTotal = hourPoints.reduce(0) { $0 + $1.nudges }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(L("stats.activity.title"))
                    .font(.headline)
                Spacer()
                Picker("", selection: $chartPeriod) {
                    ForEach(StatsChartPeriod.allCases) { period in
                        Text(period.label).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
                .labelsHidden()
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: 16) {
                    if periodTotal == 0 {
                        chartEmpty(message: L("stats.chart.empty"))
                    } else {
                        dailyChart(points: dayPoints)
                        Text(L("stats.activity.period_total \(periodTotal)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider().opacity(0.4)

                    selectedDayHeader(dayTotal: dayTotal)
                    hourlyChart(points: hourPoints, total: dayTotal)
                }
            }
        }
    }

    private func selectedDayHeader(dayTotal: Int) -> some View {
        HStack(spacing: 8) {
            Button {
                shiftFocusedDay(by: -1)
            } label: {
                Image(systemName: "chevron.backward")
            }
            .buttonStyle(.borderless)
            .disabled(focusedDay <= earliestAllowedDay)
            .help(L("stats.chart.prev_day"))

            VStack(alignment: .leading, spacing: 2) {
                Text(focusedDayTitle)
                    .font(.subheadline.weight(.semibold))
                Text(L("stats.activity.day_hours \(dayTotal)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                shiftFocusedDay(by: 1)
            } label: {
                Image(systemName: "chevron.forward")
            }
            .buttonStyle(.borderless)
            .disabled(focusedDay >= latestAllowedDay)
            .help(L("stats.chart.next_day"))

            if !calendar.isDateInToday(focusedDay) {
                Button(L("stats.chart.today")) {
                    focusedDay = latestAllowedDay
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            Spacer(minLength: 0)
        }
    }

    private var focusedDayTitle: String {
        if calendar.isDateInToday(focusedDay) {
            return L("stats.activity.today_hours")
        }
        return focusedDay.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private func dailyChart(points: [DayNudgePoint]) -> some View {
        Chart(points) { point in
            BarMark(
                x: .value(L("stats.chart.day"), point.day, unit: .day),
                y: .value(L("stats.kpi.nudges"), point.nudges)
            )
            .foregroundStyle(
                calendar.isDate(point.day, inSameDayAs: focusedDay)
                    ? Color.accentColor
                    : Color.accentColor.opacity(0.32)
            )
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let plotOrigin: CGFloat
                        if let plotFrame = proxy.plotFrame {
                            plotOrigin = geo[plotFrame].origin.x
                        } else {
                            plotOrigin = 0
                        }
                        let x = location.x - plotOrigin
                        guard let date: Date = proxy.value(atX: x) else { return }
                        selectDay(date)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: chartStride)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(
                            date,
                            format: chartPeriod == .days7
                                ? .dateTime.weekday(.abbreviated)
                                : .dateTime.day().month(.abbreviated)
                        )
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 160)
    }

    private func hourlyChart(points: [HourNudgePoint], total: Int) -> some View {
        let yMax = max(1, points.map(\.nudges).max() ?? 1)

        return VStack(alignment: .leading, spacing: 8) {
            Chart(points) { point in
                BarMark(
                    x: .value(L("stats.chart.hour"), point.hourOfDay),
                    y: .value(L("stats.kpi.nudges"), point.nudges)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
            .chartXScale(domain: -0.5...23.5)
            .chartYScale(domain: 0...Double(yMax))
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text(String(format: "%02d", hour))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 120)

            if total == 0 {
                Text(L("stats.chart.empty_day"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(L("stats.chart.hourly_caption"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func chartEmpty(message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 28)
            Spacer()
        }
    }

    private func selectDay(_ date: Date) {
        let day = calendar.startOfDay(for: date)
        focusedDay = min(max(day, earliestAllowedDay), latestAllowedDay)
    }

    private func shiftFocusedDay(by delta: Int) {
        guard let next = calendar.date(byAdding: .day, value: delta, to: focusedDay) else { return }
        selectDay(next)
    }

}
