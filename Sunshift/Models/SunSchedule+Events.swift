import Foundation

extension SunSchedule {

    // MARK: - Ordered Events

    /// All non-nil events for this schedule, sorted chronologically.
    /// Covers the practical light events; civil twilight aliases (firstLight/lastLight) are omitted
    /// to avoid duplicates.
    var orderedEvents: [SunEvent] {
        let candidates: [(SunEventType, Date?)] = [
            (.firstLight,      firstLight),
            (.blueHourStart,   blueHourStart),
            (.sunrise,         sunrise),
            (.goldenHourStart, goldenHourStart),
            (.solarNoon,       solarNoon),
            (.goldenHourEnd,   goldenHourEnd),
            (.sunset,          sunset),
            (.blueHourEnd,     blueHourEnd),
            (.lastLight,       lastLight),
        ]
        return candidates.compactMap { type, date in
            date.map { SunEvent(type: type, time: $0) }
        }
        .sorted { $0.time < $1.time }
    }

    // MARK: - Daylight Remaining

    /// Remaining daylight at `now`.
    ///
    /// Returns `nil` when:
    /// - `sunset` is unavailable (polar day/night)
    /// - `now` is at or after `sunset`
    /// - `now` is not on the same local calendar day as `sunset`
    func daylightRemaining(at now: Date) -> TimeInterval? {
        guard let tz = TimeZone(identifier: timeZoneIdentifier),
              let set = sunset,
              now < set,
              now.isSameLocalDay(as: set, in: tz) else { return nil }
        return set.timeIntervalSince(now)
    }

    // MARK: - Event Lookup

    /// Returns the point-in-time Date for a given SunEventType, or nil for non-point types
    /// (e.g. daylightRemaining) or when the event did not occur (polar day/night).
    func event(for type: SunEventType) -> Date? {
        switch type {
        case .sunrise:            return sunrise
        case .sunset:             return sunset
        case .solarNoon:          return solarNoon
        case .goldenHourStart:    return goldenHourStart
        case .goldenHourEnd:      return goldenHourEnd
        case .blueHourStart:      return blueHourStart
        case .blueHourEnd:        return blueHourEnd
        case .firstLight:         return firstLight
        case .lastLight:          return lastLight
        case .civilTwilightStart: return civilTwilightStart
        case .civilTwilightEnd:   return civilTwilightEnd
        case .daylightRemaining:  return nil
        }
    }

    // MARK: - Next Event

    /// The next scheduled event strictly after `now`, or `nil` if all events have passed.
    func nextEvent(after now: Date) -> SunEvent? {
        orderedEvents.first { $0.time > now }
    }
}
