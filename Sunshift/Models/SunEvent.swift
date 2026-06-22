import Foundation

struct SunEvent {
    let date: Date
    let sunrise: Date
    let sunset: Date

    var goldenHourMorning: DateInterval {
        DateInterval(start: sunrise, duration: 3600)
    }
    var goldenHourEvening: DateInterval {
        DateInterval(start: sunset.addingTimeInterval(-3600), duration: 3600)
    }
}
