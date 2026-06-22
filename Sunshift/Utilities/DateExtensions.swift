import Foundation

extension Date {
    var isToday: Bool { Calendar.current.isDateInToday(self) }

    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    func startOfDay(in timeZone: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.startOfDay(for: self)
    }

    /// Adds calendar days in a specific timezone, handling DST correctly.
    func addingDays(_ days: Int, in timeZone: TimeZone) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.date(byAdding: .day, value: days, to: self)
            ?? addingTimeInterval(Double(days) * 86400)
    }

    func isSameLocalDay(as other: Date, in timeZone: TimeZone) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.isDate(self, inSameDayAs: other)
    }

    /// Returns a short time string respecting the device's 12h/24h preference, e.g. "6:14 AM".
    func formattedTime(in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    /// Creates a Date at midnight on the given calendar date in the specified timezone.
    /// Returns nil if the components do not form a valid date.
    static func localDate(year: Int, month: Int, day: Int, timeZone: TimeZone) -> Date? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        var dc = DateComponents()
        dc.year = year; dc.month = month; dc.day = day
        dc.hour = 0; dc.minute = 0; dc.second = 0
        return cal.date(from: dc)
    }
}
