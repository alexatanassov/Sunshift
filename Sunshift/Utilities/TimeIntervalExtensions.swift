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

    /// Formats a countdown with second-level precision, e.g. "1h 24m 08s", "12m 04s", or "45s".
    var formattedDurationWithSeconds: String {
        let total = max(0, Int(self))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%dh %dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
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
