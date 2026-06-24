import Foundation

struct RoutineScheduler {

    // Returns the next trigger date for `routine` strictly after `now`.
    // Scans today through the next 7 days and returns the first valid trigger.
    // Returns nil when no trigger is found (event unavailable, weekday never matches, etc.).
    static func nextTriggerDate(
        for routine: LightRoutine,
        sunService: SunService,
        location: SavedLocation,
        after now: Date
    ) -> Date? {
        let tz = TimeZone(identifier: location.timeZoneIdentifier) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        for dayOffset in 0..<8 {
            guard let targetDay = cal.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let startOfDay = cal.startOfDay(for: targetDay)

            let weekday = cal.component(.weekday, from: startOfDay)
            guard routine.selectedWeekdays.contains(calendarWeekday: weekday) else { continue }

            let input = SunCalculationInput(
                date: startOfDay,
                latitude: location.latitude,
                longitude: location.longitude,
                timeZoneIdentifier: location.timeZoneIdentifier
            )
            guard let schedule = try? sunService.sunSchedule(for: input) else { continue }
            guard let eventDate = schedule.event(for: routine.sunEventType) else { continue }

            let offsetSeconds = TimeInterval(routine.offsetMinutes) * 60
            let trigger = routine.isBeforeEvent ? eventDate - offsetSeconds : eventDate + offsetSeconds

            if trigger > now {
                return trigger
            }
        }

        return nil
    }
}
