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
