import Foundation

enum SessionDuration: String, CaseIterable, Identifiable {
    case always
    case h1 = "1"
    case h4 = "4"
    case h8 = "8"

    var id: String { rawValue }

    var seconds: TimeInterval? {
        switch self {
        case .always: return nil
        case .h1: return 3600
        case .h4: return 14400
        case .h8: return 28800
        }
    }

    var label: String {
        switch self {
        case .always: return "∞"
        case .h1: return L("menubar.duration.chip_1h")
        case .h4: return L("menubar.duration.chip_4h")
        case .h8: return L("menubar.duration.chip_8h")
        }
    }

    var sessionLabel: String {
        switch self {
        case .always: return L("menubar.duration.always")
        case .h1: return L("menubar.duration.1h")
        case .h4: return L("menubar.duration.4h")
        case .h8: return L("menubar.duration.8h")
        }
    }
}
