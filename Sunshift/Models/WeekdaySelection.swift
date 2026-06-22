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
}
