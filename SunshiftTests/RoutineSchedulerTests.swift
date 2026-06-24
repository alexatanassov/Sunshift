import Testing
import Foundation
@testable import Sunshift

struct RoutineSchedulerTests {

    // MARK: - Helpers

    private func makeLocation(
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        tzID: String = "America/Los_Angeles"
    ) -> SavedLocation {
        SavedLocation(
            name: "San Francisco",
            subtitle: "San Francisco, CA",
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: tzID,
            source: .manual,
            isCurrentLocation: false
        )
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0,
                          tzID: String = "America/Los_Angeles") throws -> Date {
        let tz = try #require(TimeZone(identifier: tzID))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var dc = DateComponents()
        dc.year = year; dc.month = month; dc.day = day
        dc.hour = hour; dc.minute = minute; dc.second = 0
        return try #require(cal.date(from: dc))
    }

    private func makeRoutine(
        sunEventType: SunEventType = .sunset,
        offsetMinutes: Int = 30,
        isBeforeEvent: Bool = true,
        selectedWeekdays: WeekdaySelection = .everyday
    ) -> LightRoutine {
        LightRoutine(
            title: "Test Routine",
            sunEventType: sunEventType,
            offsetMinutes: offsetMinutes,
            isBeforeEvent: isBeforeEvent,
            selectedWeekdays: selectedWeekdays,
            isEnabled: true
        )
    }

    // MARK: - Basic scheduling

    @Test func returnsFutureTriggerBeforeEvent() throws {
        // Noon on a summer day in SF — sunset is around 8:30 PM, trigger at 8:00 PM
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let routine = makeRoutine(sunEventType: .sunset, offsetMinutes: 30, isBeforeEvent: true)
        let location = makeLocation()

        let result = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: SunService(),
            location: location,
            after: now
        )

        let trigger = try #require(result)
        #expect(trigger > now)
    }

    @Test func returnsFutureTriggerAfterEvent() throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let routine = makeRoutine(sunEventType: .sunrise, offsetMinutes: 15, isBeforeEvent: false)
        let location = makeLocation()

        let result = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: SunService(),
            location: location,
            after: now
        )

        // Sunrise already passed (it's noon), so should return tomorrow
        let trigger = try #require(result)
        #expect(trigger > now)
    }

    @Test func triggerIsEventDateMinusOffset() throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let routine = makeRoutine(sunEventType: .sunset, offsetMinutes: 30, isBeforeEvent: true)
        let location = makeLocation()
        let svc = SunService()

        let trigger = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: svc,
            location: location,
            after: now
        )

        // Independently compute today's sunset and verify offset
        let tz = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let startOfDay = cal.startOfDay(for: now)
        let input = SunCalculationInput(
            date: startOfDay,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneIdentifier: location.timeZoneIdentifier
        )
        let schedule = try svc.sunSchedule(for: input)
        let expectedSunset = try #require(schedule.sunset)
        let expectedTrigger = expectedSunset - 30 * 60

        let result = try #require(trigger)
        // Allow 1 second tolerance for floating-point math
        #expect(abs(result.timeIntervalSince(expectedTrigger)) < 1)
    }

    // MARK: - Past trigger rolls to next day

    @Test func todayTriggerPassedRollsToTomorrow() throws {
        // 11 PM on a summer day — today's sunset trigger has long passed
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 23)
        let routine = makeRoutine(sunEventType: .sunset, offsetMinutes: 30, isBeforeEvent: true)
        let location = makeLocation()

        let result = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: SunService(),
            location: location,
            after: now
        )

        let trigger = try #require(result)
        // Result should be tomorrow (more than 1 hour ahead)
        #expect(trigger > now.addingTimeInterval(60 * 60))
    }

    // MARK: - Weekday filtering

    @Test func skipsNonMatchingWeekdays() throws {
        // 2026-06-23 is a Tuesday. Set routine to weekends only.
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let routine = makeRoutine(selectedWeekdays: .weekends)
        let location = makeLocation()

        let result = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: SunService(),
            location: location,
            after: now
        )

        let trigger = try #require(result)
        // Next weekend day from Tuesday is Saturday (4 days away)
        let tz = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let weekday = cal.component(.weekday, from: trigger)
        // Saturday = 7, Sunday = 1
        #expect(weekday == 7 || weekday == 1)
    }

    // MARK: - Returns nil for empty weekday selection

    @Test func returnsNilForEmptyWeekdaySelection() throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let routine = makeRoutine(selectedWeekdays: WeekdaySelection(rawValue: 0))
        let location = makeLocation()

        let result = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: SunService(),
            location: location,
            after: now
        )

        #expect(result == nil)
    }

    // MARK: - Morning light: 15 min after sunrise

    @Test func morningLightTriggerIsEventDatePlusOffset() throws {
        // 4:00 AM — well before sunrise (~5:47 AM) in SF on a June day.
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 4)
        let routine = makeRoutine(sunEventType: .sunrise, offsetMinutes: 15, isBeforeEvent: false)
        let location = makeLocation()
        let svc = SunService()

        let trigger = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: svc,
            location: location,
            after: now
        )

        let tz = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let startOfDay = cal.startOfDay(for: now)
        let input = SunCalculationInput(
            date: startOfDay,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneIdentifier: location.timeZoneIdentifier
        )
        let schedule = try svc.sunSchedule(for: input)
        let expectedSunrise = try #require(schedule.sunrise)
        let expectedTrigger = expectedSunrise + 15 * 60

        let result = try #require(trigger)
        #expect(abs(result.timeIntervalSince(expectedTrigger)) < 1)
        #expect(result > now)
    }

    // MARK: - Disabled routine

    @Test func disabledRoutineReturnsNil() throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let routine = LightRoutine(
            title: "Disabled",
            sunEventType: .sunset,
            offsetMinutes: 30,
            isBeforeEvent: true,
            selectedWeekdays: .everyday,
            isEnabled: false
        )
        let location = makeLocation()

        let result = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: SunService(),
            location: location,
            after: now
        )

        #expect(result == nil)
    }

    // MARK: - Non-Pacific timezone

    @Test func nonPacificTimezoneYieldsCorrectTrigger() throws {
        // New York, noon on a summer day — sunset is still hours away (~8:28 PM EDT).
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12, tzID: "America/New_York")
        let location = makeLocation(latitude: 40.7128, longitude: -74.0060, tzID: "America/New_York")
        let routine = makeRoutine(sunEventType: .sunset, offsetMinutes: 30, isBeforeEvent: true)
        let svc = SunService()

        let trigger = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: svc,
            location: location,
            after: now
        )

        let tz = try #require(TimeZone(identifier: "America/New_York"))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let startOfDay = cal.startOfDay(for: now)
        let input = SunCalculationInput(
            date: startOfDay,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneIdentifier: location.timeZoneIdentifier
        )
        let schedule = try svc.sunSchedule(for: input)
        let expectedSunset = try #require(schedule.sunset)
        let expectedTrigger = expectedSunset - 30 * 60

        let result = try #require(trigger)
        #expect(abs(result.timeIntervalSince(expectedTrigger)) < 1)
        #expect(result > now)
    }

    // MARK: - Polar conditions return nil for unavailable event

    @Test func returnsNilWhenEventUnavailableAllDays() throws {
        // Tromsø in midsummer: no sunset
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "Europe/Oslo")
        let routine = makeRoutine(sunEventType: .sunset, selectedWeekdays: .everyday)
        let location = makeLocation(latitude: 69.6492, longitude: 18.9553, tzID: "Europe/Oslo")

        let result = RoutineScheduler.nextTriggerDate(
            for: routine,
            sunService: SunService(),
            location: location,
            after: now
        )

        #expect(result == nil)
    }
}
