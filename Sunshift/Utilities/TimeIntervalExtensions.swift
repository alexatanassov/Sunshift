import Foundation

extension TimeInterval {

    /// Formats as "13h 57m" or "45m" for durations under one hour.
    var formattedDuration: String {
        formatHoursAndMinutes()
    }

    /// Formats remaining daylight as "2h 14m" or "45m".
    var formattedDaylightRemaining: String {
        formatHoursAndMinutes()
    }

    /// Formats a positive future interval as a countdown, e.g. "in 2h 14m" or "in 45m".
    /// Returns "starting now" for intervals under one minute.
    var formattedCountdown: String {
        guard self >= 60 else { return "starting now" }
        return "in \(formatHoursAndMinutes())"
    }

    private func formatHoursAndMinutes() -> String {
        let totalMinutes = max(0, Int(self / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
