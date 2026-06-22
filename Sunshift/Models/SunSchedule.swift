import Foundation

struct SunSchedule: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String

    // Optional: nil when the event does not occur (polar day / polar night)
    let sunrise: Date?
    let sunset: Date?
    let solarNoon: Date?
    let goldenHourStart: Date?
    let goldenHourEnd: Date?
    let blueHourStart: Date?
    let blueHourEnd: Date?
    let firstLight: Date?
    let lastLight: Date?
    let civilTwilightStart: Date?
    let civilTwilightEnd: Date?

    let daylightDuration: TimeInterval?
    let daylightRemaining: TimeInterval?
    let nextEvent: SunEvent?

    init(
        id: UUID = UUID(),
        date: Date,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        sunrise: Date? = nil,
        sunset: Date? = nil,
        solarNoon: Date? = nil,
        goldenHourStart: Date? = nil,
        goldenHourEnd: Date? = nil,
        blueHourStart: Date? = nil,
        blueHourEnd: Date? = nil,
        firstLight: Date? = nil,
        lastLight: Date? = nil,
        civilTwilightStart: Date? = nil,
        civilTwilightEnd: Date? = nil,
        daylightDuration: TimeInterval? = nil,
        daylightRemaining: TimeInterval? = nil,
        nextEvent: SunEvent? = nil
    ) {
        self.id = id
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.sunrise = sunrise
        self.sunset = sunset
        self.solarNoon = solarNoon
        self.goldenHourStart = goldenHourStart
        self.goldenHourEnd = goldenHourEnd
        self.blueHourStart = blueHourStart
        self.blueHourEnd = blueHourEnd
        self.firstLight = firstLight
        self.lastLight = lastLight
        self.civilTwilightStart = civilTwilightStart
        self.civilTwilightEnd = civilTwilightEnd
        self.daylightDuration = daylightDuration
        self.daylightRemaining = daylightRemaining
        self.nextEvent = nextEvent
    }
}
