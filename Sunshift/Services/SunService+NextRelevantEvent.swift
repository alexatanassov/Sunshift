import Foundation

extension SunService {

    /// Returns the next relevant event after `now`.
    ///
    /// First checks `schedule` for any upcoming event today. If all events have passed,
    /// calculates tomorrow's schedule from `input` and returns its first event.
    /// Returns `nil` only when tomorrow's schedule also has no events (e.g., polar conditions).
    func nextRelevantEvent(
        after now: Date,
        schedule: SunSchedule,
        input: SunCalculationInput
    ) throws -> SunEvent? {
        if let event = schedule.nextEvent(after: now) {
            return event
        }
        guard let tz = TimeZone(identifier: input.timeZoneIdentifier) else { return nil }
        let tomorrowInput = SunCalculationInput(
            date: input.date.addingDays(1, in: tz),
            latitude: input.latitude,
            longitude: input.longitude,
            timeZoneIdentifier: input.timeZoneIdentifier
        )
        let tomorrow = try sunSchedule(for: tomorrowInput)
        return tomorrow.orderedEvents.first
    }
}
