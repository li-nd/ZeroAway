import Foundation

enum DurationFormat {
    /// Compact duration for UI: `45s` / `2m` / `1m 30s` (locale-aware).
    static func short(seconds: Int) -> String {
        let value = TimeInterval(max(0, seconds))
        if let string = shortFormatter.string(from: value), !string.isEmpty {
            return string
        }
        return fallbackSeconds(Int(value))
    }

    /// Full countdown omitting leading zero units: `1d 21h 12m 7s` (locale-aware).
    static func countdown(seconds: Int) -> String {
        let value = TimeInterval(max(0, seconds))
        if let string = countdownFormatter.string(from: value), !string.isEmpty {
            return string
        }
        return fallbackSeconds(Int(value))
    }

    /// Locale-aware relative time: `5 seconds ago` / `2 minutes ago`.
    static func relative(from date: Date, to reference: Date = .now) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: reference)
    }

    static func setLocale(_ locale: Locale) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        shortFormatter.calendar = calendar
        countdownFormatter.calendar = calendar
        relativeFormatter.locale = locale
        relativeFormatter.calendar = calendar
    }

    // MARK: - Formatters

    private static let shortFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = [.dropLeading, .dropTrailing]
        formatter.collapsesLargestUnit = true
        return formatter
    }()

    private static let countdownFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .numeric
        return formatter
    }()

    private static func fallbackSeconds(_ seconds: Int) -> String {
        Duration.seconds(seconds).formatted(
            .units(allowed: [.seconds], width: .abbreviated)
        )
    }
}

enum IdleThresholdSlider {
    static let stepSeconds = 5
    static let minSeconds = 5
    static let maxSeconds = 20 * 60

    static func clamp(_ seconds: Int) -> Int {
        min(maxSeconds, max(minSeconds, seconds))
    }

    static func snap(_ seconds: Int) -> Int {
        let value = clamp(seconds)
        let stepped = Int((Double(value) / Double(stepSeconds)).rounded()) * stepSeconds
        return max(minSeconds, min(maxSeconds, stepped))
    }

    /// Maps threshold → slider position (0…1), emphasizing lower values.
    static func position(for seconds: Int) -> Double {
        let range = Double(maxSeconds - minSeconds)
        let normalized = (Double(clamp(seconds)) - Double(minSeconds)) / range
        return sqrt(max(0, min(1, normalized)))
    }

    /// Maps slider position (0…1) → threshold seconds.
    static func seconds(for position: Double) -> Int {
        let t = max(0, min(1, position))
        let range = Double(maxSeconds - minSeconds)
        let raw = Double(minSeconds) + range * t * t
        return snap(Int(raw.rounded()))
    }
}

enum NudgeDistanceSlider {
    static let minPixels = 1
    static let maxPixels = 10

    static func clamp(_ pixels: Int) -> Int {
        min(maxPixels, max(minPixels, pixels))
    }
}
