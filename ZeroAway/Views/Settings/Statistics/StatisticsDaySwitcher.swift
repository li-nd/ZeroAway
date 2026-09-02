import SwiftUI

/// Shared day pager used by charts and session history (same `focusedDay` binding).
struct StatisticsDaySwitcher: View {
    @Binding var focusedDay: Date
    let earliestDay: Date
    let latestDay: Date
    let title: String
    let subtitle: String

    private var calendar: Calendar { .current }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                shift(by: -1)
            } label: {
                Image(systemName: "chevron.backward")
            }
            .buttonStyle(.borderless)
            .disabled(focusedDay <= earliestDay)
            .help(L("stats.chart.prev_day"))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                shift(by: 1)
            } label: {
                Image(systemName: "chevron.forward")
            }
            .buttonStyle(.borderless)
            .disabled(focusedDay >= latestDay)
            .help(L("stats.chart.next_day"))

            if !calendar.isDateInToday(focusedDay) {
                Button(L("stats.chart.today")) {
                    focusedDay = latestDay
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            Spacer(minLength: 0)
        }
    }

    private func shift(by delta: Int) {
        guard let next = calendar.date(byAdding: .day, value: delta, to: focusedDay) else { return }
        let day = calendar.startOfDay(for: next)
        focusedDay = min(max(day, earliestDay), latestDay)
    }
}

enum StatisticsDayTitle {
    static func title(for day: Date, todayLabel: String? = nil) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) {
            return todayLabel ?? L("stats.chart.today")
        }
        if calendar.isDateInYesterday(day) {
            return L("stats.history.yesterday")
        }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}
