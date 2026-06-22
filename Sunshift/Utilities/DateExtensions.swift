import Foundation

extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }

    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}
