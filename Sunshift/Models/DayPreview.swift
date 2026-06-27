import Foundation

struct DayPreview: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let timeZoneIdentifier: String
    let sunrise: Date?
    let sunset: Date?
    let goldenHourStart: Date?
    let goldenHourEnd: Date?
    let lastLight: Date?
    let daylightDuration: TimeInterval?
}
