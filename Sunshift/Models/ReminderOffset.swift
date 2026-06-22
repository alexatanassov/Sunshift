import Foundation

enum ReminderOffset: Equatable {
    case atEvent
    case preset(minutes: Int)
    case custom(minutes: Int)

    static let fiveMinutes    = ReminderOffset.preset(minutes: 5)
    static let tenMinutes     = ReminderOffset.preset(minutes: 10)
    static let fifteenMinutes = ReminderOffset.preset(minutes: 15)
    static let thirtyMinutes  = ReminderOffset.preset(minutes: 30)
    static let oneHour        = ReminderOffset.preset(minutes: 60)

    static var presets: [ReminderOffset] {
        [.atEvent, .fiveMinutes, .tenMinutes, .fifteenMinutes, .thirtyMinutes, .oneHour]
    }

    var offsetMinutes: Int {
        switch self {
        case .atEvent:               return 0
        case .preset(let minutes):   return minutes
        case .custom(let minutes):   return minutes
        }
    }

    var displayName: String {
        switch self {
        case .atEvent:             return "At event"
        case .preset(let minutes): return minutesLabel(minutes)
        case .custom(let minutes): return "\(minutesLabel(minutes)) (custom)"
        }
    }

    private func minutesLabel(_ minutes: Int) -> String {
        minutes < 60 ? "\(minutes) min before" : "\(minutes / 60) hr before"
    }
}
