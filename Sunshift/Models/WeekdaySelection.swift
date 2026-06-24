import Foundation

struct WeekdaySelection: OptionSet, Codable {
    let rawValue: Int

    static let sunday    = WeekdaySelection(rawValue: 1 << 0)
    static let monday    = WeekdaySelection(rawValue: 1 << 1)
    static let tuesday   = WeekdaySelection(rawValue: 1 << 2)
    static let wednesday = WeekdaySelection(rawValue: 1 << 3)
    static let thursday  = WeekdaySelection(rawValue: 1 << 4)
    static let friday    = WeekdaySelection(rawValue: 1 << 5)
    static let saturday  = WeekdaySelection(rawValue: 1 << 6)

    static let everyday: WeekdaySelection = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    static let weekdays: WeekdaySelection = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekends: WeekdaySelection = [.saturday, .sunday]

    // Calendar.weekday: 1=Sunday, 2=Monday, ..., 7=Saturday
    func contains(calendarWeekday: Int) -> Bool {
        switch calendarWeekday {
        case 1: return contains(.sunday)
        case 2: return contains(.monday)
        case 3: return contains(.tuesday)
        case 4: return contains(.wednesday)
        case 5: return contains(.thursday)
        case 6: return contains(.friday)
        case 7: return contains(.saturday)
        default: return false
        }
    }

    var friendlyLabel: String {
        if self == .everyday { return "Every day" }
        if self == .weekdays { return "Weekdays" }
        if self == .weekends { return "Weekends" }
        let ordered: [(WeekdaySelection, String)] = [
            (.monday, "Mon"), (.tuesday, "Tue"), (.wednesday, "Wed"),
            (.thursday, "Thu"), (.friday, "Fri"), (.saturday, "Sat"), (.sunday, "Sun")
        ]
        let names = ordered.filter { contains($0.0) }.map(\.1)
        return names.isEmpty ? "Never" : names.joined(separator: ", ")
    }
}
