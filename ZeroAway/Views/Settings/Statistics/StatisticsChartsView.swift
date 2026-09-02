import Charts
import SwiftUI

struct StatisticsChartsView: View {
    @ObservedObject var stats: UsageStatsStore
    @Binding var chartPeriod: StatsChartPeriod
    @Binding var focusedDay: Date
    let tick: Date
    let earliestAllowedDay: Date
    let latestAllowedDay: Date

    @State private var dailyHover: DayNudgePoint?
    @State private var dailyHoverX: CGFloat?
    @State private var hourlyHover: HourNudgePoint?
    @State private var hourlyHoverX: CGFloat?

    private var calendar: Calendar { .current }

    private var chartStride: Int {
        switch chartPeriod {
        case .days7: return 1
        case .days30: return 5
        case .days90: return 14
        case .days180: return 30
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
                .frame(maxWidth: 280)
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
        .onChange(of: chartPeriod) { _, _ in
            dailyHover = nil
            dailyHoverX = nil
            hourlyHover = nil
            hourlyHoverX = nil
        }
        .onChange(of: focusedDay) { _, _ in
            hourlyHover = nil
            hourlyHoverX = nil
        }
    }

    private func selectedDayHeader(dayTotal: Int) -> some View {
        StatisticsDaySwitcher(
            focusedDay: $focusedDay,
            earliestDay: earliestAllowedDay,
            latestDay: latestAllowedDay,
            title: focusedDayTitle,
            subtitle: L("stats.activity.day_hours \(dayTotal)")
        )
    }

    private var focusedDayTitle: String {
        if calendar.isDateInToday(focusedDay) {
            return L("stats.activity.today_hours")
        }
        return StatisticsDayTitle.title(for: focusedDay)
    }

    private func dailyChart(points: [DayNudgePoint]) -> some View {
        let yMax = niceYMax(points.map(\.nudges).max() ?? 0)

        return Chart {
            ForEach(points) { point in
                BarMark(
                    x: .value(L("stats.chart.day"), point.day, unit: .day),
                    y: .value(L("stats.kpi.nudges"), point.nudges)
                )
                .foregroundStyle(dailyBarColor(for: point))
            }

            if let hover = dailyHover {
                RuleMark(x: .value(L("stats.chart.day"), hover.day, unit: .day))
                    .foregroundStyle(Color.primary.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartYScale(domain: 0...yMax)
        .chartOverlay { proxy in
            GeometryReader { geo in
                let plotOrigin = plotOriginX(proxy: proxy, geo: geo)
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                let x = location.x - plotOrigin
                                guard let date: Date = proxy.value(atX: x) else {
                                    dailyHover = nil
                                    dailyHoverX = nil
                                    return
                                }
                                let day = calendar.startOfDay(for: date)
                                dailyHover = points.first { calendar.isDate($0.day, inSameDayAs: day) }
                                if let hover = dailyHover, let px = proxy.position(forX: hover.day) {
                                    dailyHoverX = plotOrigin + px
                                } else {
                                    dailyHoverX = location.x
                                }
                            case .ended:
                                dailyHover = nil
                                dailyHoverX = nil
                            }
                        }
                        .onTapGesture { location in
                            let x = location.x - plotOrigin
                            guard let date: Date = proxy.value(atX: x) else { return }
                            selectDay(date)
                        }

                    if let hover = dailyHover, let x = dailyHoverX {
                        chartTooltip(
                            title: dailyHoverTitle(hover.day),
                            value: hover.nudges
                        )
                        .position(
                            x: clampedTooltipX(x, width: geo.size.width),
                            y: 22
                        )
                        .allowsHitTesting(false)
                    }
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
        .frame(height: 176)
    }

    private func hourlyChart(points: [HourNudgePoint], total: Int) -> some View {
        let yMax = niceYMax(points.map(\.nudges).max() ?? 0)

        return VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(points) { point in
                    BarMark(
                        x: .value(L("stats.chart.hour"), point.hourOfDay),
                        y: .value(L("stats.kpi.nudges"), point.nudges)
                    )
                    .foregroundStyle(
                        hourlyHover?.hourOfDay == point.hourOfDay
                            ? Color.accentColor
                            : Color.accentColor.opacity(0.85)
                    )
                }

                if let hover = hourlyHover {
                    RuleMark(x: .value(L("stats.chart.hour"), hover.hourOfDay))
                        .foregroundStyle(Color.primary.opacity(0.25))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }
            .chartXScale(domain: -0.5...23.5)
            .chartYScale(domain: 0...yMax)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotOrigin = plotOriginX(proxy: proxy, geo: geo)
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onContinuousHover { phase in
                                switch phase {
                                case .active(let location):
                                    let x = location.x - plotOrigin
                                    guard let hour = hourValue(atX: x, proxy: proxy) else {
                                        hourlyHover = nil
                                        hourlyHoverX = nil
                                        return
                                    }
                                    hourlyHover = points.first { $0.hourOfDay == hour }
                                    if let hover = hourlyHover, let px = proxy.position(forX: hover.hourOfDay) {
                                        hourlyHoverX = plotOrigin + px
                                    } else {
                                        hourlyHoverX = location.x
                                    }
                                case .ended:
                                    hourlyHover = nil
                                    hourlyHoverX = nil
                                }
                            }

                        if let hover = hourlyHover, let x = hourlyHoverX {
                            chartTooltip(
                                title: hourlyHoverTitle(hover.hourOfDay),
                                value: hover.nudges
                            )
                            .position(
                                x: clampedTooltipX(x, width: geo.size.width),
                                y: 22
                            )
                            .allowsHitTesting(false)
                        }
                    }
                }
            }
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
            .frame(height: 136)

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

    private func chartTooltip(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value) \(L("stats.kpi.nudges"))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func dailyBarColor(for point: DayNudgePoint) -> Color {
        if calendar.isDate(point.day, inSameDayAs: focusedDay) {
            return Color.accentColor
        }
        if let hover = dailyHover, calendar.isDate(point.day, inSameDayAs: hover.day) {
            return Color.accentColor.opacity(0.72)
        }
        return Color.accentColor.opacity(0.32)
    }

    private func dailyHoverTitle(_ day: Date) -> String {
        if calendar.isDateInToday(day) {
            return L("stats.activity.today_hours")
        }
        return day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    private func hourlyHoverTitle(_ hour: Int) -> String {
        let next = (hour + 1) % 24
        return String(format: "%02d:00–%02d:00", hour, next)
    }

    private func plotOriginX(proxy: ChartProxy, geo: GeometryProxy) -> CGFloat {
        if let plotFrame = proxy.plotFrame {
            return geo[plotFrame].origin.x
        }
        return 0
    }

    private func clampedTooltipX(_ x: CGFloat, width: CGFloat) -> CGFloat {
        min(max(x, 72), max(72, width - 72))
    }

    /// Keeps the Y axis stable and readable (same top whether hovered or not).
    private func niceYMax(_ rawMax: Int) -> Double {
        let value = max(1, rawMax)
        if value <= 5 { return 5 }
        if value <= 10 { return 10 }
        let step: Int
        switch value {
        case 1...50: step = 10
        case 51...100: step = 20
        case 101...250: step = 50
        case 251...500: step = 100
        default: step = 200
        }
        return Double(((value + step - 1) / step) * step)
    }

    private func hourValue(atX x: CGFloat, proxy: ChartProxy) -> Int? {
        if let hour: Int = proxy.value(atX: x) {
            return min(23, max(0, hour))
        }
        if let hour: Double = proxy.value(atX: x) {
            return min(23, max(0, Int(hour.rounded())))
        }
        return nil
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
}
