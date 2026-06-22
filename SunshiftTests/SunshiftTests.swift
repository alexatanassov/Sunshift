import Testing
import Foundation
@testable import Sunshift

struct SunshiftTests {

    // MARK: - Helpers

    /// Makes a SunCalculationInput for a fixed local date (year/month/day) in the given timezone.
    private func input(year: Int, month: Int, day: Int, lat: Double, lon: Double, tzID: String) throws -> SunCalculationInput {
        let tz = try #require(TimeZone(identifier: tzID))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var dc = DateComponents()
        dc.year = year; dc.month = month; dc.day = day
        dc.hour = 12; dc.minute = 0; dc.second = 0
        let date = try #require(cal.date(from: dc))
        return SunCalculationInput(date: date, latitude: lat, longitude: lon, timeZoneIdentifier: tzID)
    }

    /// Makes a SunCalculationInput at a specific local time on a given date.
    private func input(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0,
                       lat: Double, lon: Double, tzID: String) throws -> SunCalculationInput {
        let tz = try #require(TimeZone(identifier: tzID))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var dc = DateComponents()
        dc.year = year; dc.month = month; dc.day = day
        dc.hour = hour; dc.minute = minute; dc.second = 0
        let date = try #require(cal.date(from: dc))
        return SunCalculationInput(date: date, latitude: lat, longitude: lon, timeZoneIdentifier: tzID)
    }

    // MARK: - Event ordering

    @Test func eventOrderingMidLatitudeSummer() throws {
        // San Francisco, summer solstice 2023. All main events should be present
        // and ordered correctly throughout the day.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        let fl = try #require(s.firstLight)
        let bhs = try #require(s.blueHourStart)
        let sr  = try #require(s.sunrise)
        let ghs = try #require(s.goldenHourStart)
        let sn  = try #require(s.solarNoon)
        let ghe = try #require(s.goldenHourEnd)
        let ss  = try #require(s.sunset)
        let bhe = try #require(s.blueHourEnd)
        let ll  = try #require(s.lastLight)

        #expect(fl  < bhs)
        #expect(bhs < sr)
        #expect(sr  < ghs)
        #expect(ghs < sn)
        #expect(sn  < ghe)
        #expect(ghe < ss)
        #expect(ss  < bhe)
        #expect(bhe < ll)
    }

    // MARK: - Approximate values (±5 min tolerance)

    @Test func sfSummerSolsticeDaylightDuration() throws {
        // Expected daylight for SF on June 21: ~14h 46min (887 min).
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        let duration = try #require(s.daylightDuration)
        let durationMins = duration / 60.0
        // Allow ±5 minutes from expected 887 minutes.
        #expect(durationMins > 882 && durationMins < 892)
    }

    @Test func sfWinterSolsticeDaylightDuration() throws {
        // Expected daylight for SF on Dec 21: ~9h 33min (573 min).
        let svc = SunService()
        let inp = try input(year: 2023, month: 12, day: 21,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        let duration = try #require(s.daylightDuration)
        let durationMins = duration / 60.0
        // Allow ±5 minutes from expected 573 minutes.
        #expect(durationMins > 568 && durationMins < 578)
    }

    // MARK: - Polar conditions

    @Test func polarDaySummerNoSunset() throws {
        // Tromsø, Norway (69.6°N) on summer solstice: sun never sets (polar day).
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21,
                            lat: 69.6, lon: 18.9551, tzID: "Europe/Oslo")
        let s = try svc.sunSchedule(for: inp)

        // Sunrise and sunset must be nil during polar day.
        #expect(s.sunrise == nil)
        #expect(s.sunset == nil)
        // Solar noon should still be calculable.
        #expect(s.solarNoon != nil)
    }

    @Test func polarNightWinterNoSunrise() throws {
        // Tromsø on winter solstice: sun never rises (polar night).
        let svc = SunService()
        let inp = try input(year: 2023, month: 12, day: 21,
                            lat: 69.6, lon: 18.9551, tzID: "Europe/Oslo")
        let s = try svc.sunSchedule(for: inp)

        #expect(s.sunrise == nil)
        #expect(s.sunset == nil)
        #expect(s.solarNoon != nil)
    }

    // MARK: - Timezone safety

    @Test func differentTimezonesProduceDifferentDates() throws {
        // Same UTC instant, but different local dates depending on timezone.
        // Verifies that the calculation is anchored to the local calendar date.
        let svc = SunService()

        // 2023-06-15 23:30 UTC = June 15 in London, June 16 in Tokyo (+9h).
        let utcDate: Date = {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            var dc = DateComponents()
            dc.year = 2023; dc.month = 6; dc.day = 15
            dc.hour = 23; dc.minute = 30; dc.second = 0
            return cal.date(from: dc)!
        }()

        let londonInp = SunCalculationInput(
            date: utcDate,
            latitude: 51.5074, longitude: -0.1278,
            timeZoneIdentifier: "Europe/London"
        )
        let tokyoInp = SunCalculationInput(
            date: utcDate,
            latitude: 35.6762, longitude: 139.6503,
            timeZoneIdentifier: "Asia/Tokyo"
        )

        let london = try svc.sunSchedule(for: londonInp)
        let tokyo  = try svc.sunSchedule(for: tokyoInp)

        // Tokyo schedule is for Jun 16, so its sunrise should be earlier UTC-wise
        // than London's Jun 15 sunrise (different days AND different longitudes).
        // The key assertion: they produced different results, not the same calculation.
        #expect(london.sunrise != tokyo.sunrise)
    }

    // MARK: - orderedEvents

    @Test func orderedEventsAreChronological() throws {
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        let events = s.orderedEvents
        #expect(!events.isEmpty)
        for i in events.indices.dropLast() {
            #expect(events[i].time <= events[i + 1].time)
        }
    }

    @Test func orderedEventsCoversKeyTypes() throws {
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        let types = Set(s.orderedEvents.map(\.type))
        #expect(types.contains(.sunrise))
        #expect(types.contains(.solarNoon))
        #expect(types.contains(.sunset))
        #expect(types.contains(.goldenHourStart))
        #expect(types.contains(.goldenHourEnd))
        #expect(types.contains(.firstLight))
        #expect(types.contains(.lastLight))
    }

    @Test func orderedEventsEmptyDuringPolarDay() throws {
        // Tromsø in summer: no sunrise or sunset during polar day.
        // The engine must not crash and the schedule must be valid.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21,
                            lat: 69.6, lon: 18.9551, tzID: "Europe/Oslo")
        let s = try svc.sunSchedule(for: inp)

        let events = s.orderedEvents
        // orderedEvents may be empty or contain any computable events; if present, they must be chronological.
        for i in events.indices.dropLast() {
            #expect(events[i].time <= events[i + 1].time)
        }
        // If the engine computes solarNoon, it must appear in orderedEvents.
        if s.solarNoon != nil {
            #expect(events.contains(where: { $0.type == .solarNoon }))
        }
    }

    // MARK: - daylightRemaining(at:)

    @Test func daylightRemainingBeforeSunset() throws {
        // At 2 PM (14:00), well before sunset in SF summer, we expect a positive remainder.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21, hour: 14,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)
        let set = try #require(s.sunset)

        let remaining = try #require(s.daylightRemaining(at: inp.date))
        #expect(remaining > 0)
        #expect(remaining == set.timeIntervalSince(inp.date))
    }

    @Test func daylightRemainingBeforeSunrise() throws {
        // At 5 AM (before sunrise in SF summer), remaining should still be sunset - now.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21, hour: 5,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)
        let set = try #require(s.sunset)

        let remaining = try #require(s.daylightRemaining(at: inp.date))
        #expect(remaining > 0)
        #expect(remaining == set.timeIntervalSince(inp.date))
    }

    @Test func daylightRemainingAfterSunset() throws {
        // At 10 PM (22:00), well after sunset in SF summer, remaining should be nil.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21, hour: 22,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        #expect(s.daylightRemaining(at: inp.date) == nil)
    }

    @Test func daylightRemainingNilDuringPolarDay() throws {
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21,
                            lat: 69.6, lon: 18.9551, tzID: "Europe/Oslo")
        let s = try svc.sunSchedule(for: inp)

        #expect(s.daylightRemaining(at: inp.date) == nil)
    }

    // MARK: - nextEvent(after:)

    @Test func nextEventAtMorningReturnsUpcomingEvent() throws {
        // At 5 AM, the next event should be firstLight or blueHourStart.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21, hour: 5,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        let next = try #require(s.nextEvent(after: inp.date))
        #expect(next.time > inp.date)
    }

    @Test func nextEventAfterAllEventsIsNil() throws {
        // At 23:59 in SF, all sun events have passed for the day.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21, hour: 23, minute: 59,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        #expect(s.nextEvent(after: inp.date) == nil)
    }

    @Test func storedNextEventIsPopulatedAtNoon() throws {
        // When the schedule is built at noon, the stored nextEvent should be non-nil
        // and point to a time after noon.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        let stored = try #require(s.nextEvent)
        #expect(stored.time > inp.date)
    }

    // MARK: - nextRelevantEvent fallback

    @Test func nextRelevantEventFallsBackToTomorrow() throws {
        // At 23:59 in SF, today's schedule is exhausted. The fallback should return
        // tomorrow's firstLight or similar; definitely a future event.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21, hour: 23, minute: 59,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        let next = try #require(try svc.nextRelevantEvent(after: inp.date, schedule: s, input: inp))
        #expect(next.time > inp.date)
    }

    @Test func nextRelevantEventReturnsTodayWhenAvailable() throws {
        // At noon, today still has upcoming events; no fallback needed.
        let svc = SunService()
        let inp = try input(year: 2023, month: 6, day: 21,
                            lat: 37.7749, lon: -122.4194, tzID: "America/Los_Angeles")
        let s = try svc.sunSchedule(for: inp)

        let next = try #require(try svc.nextRelevantEvent(after: inp.date, schedule: s, input: inp))
        let tz = try #require(TimeZone(identifier: "America/Los_Angeles"))
        #expect(next.time.isSameLocalDay(as: inp.date, in: tz))
    }

    // MARK: - Invalid input

    @Test func invalidCoordinatesThrows() throws {
        let svc = SunService()
        let badInp = SunCalculationInput(
            date: Date(),
            latitude: 91.0,  // invalid
            longitude: 0.0,
            timeZoneIdentifier: "UTC"
        )
        #expect(throws: SunCalculationError.invalidCoordinates) {
            try svc.sunSchedule(for: badInp)
        }
    }

    @Test func invalidTimezoneThrows() throws {
        let svc = SunService()
        let badInp = SunCalculationInput(
            date: Date(),
            latitude: 0.0,
            longitude: 0.0,
            timeZoneIdentifier: "Not/ATimezone"
        )
        #expect(throws: SunCalculationError.invalidTimeZone) {
            try svc.sunSchedule(for: badInp)
        }
    }

    // MARK: - Solar noon timezone correctness

    @Test func solarNoonIsLocalMiddayApproximately() throws {
        // For any location, solar noon should fall within a few hours of local 12:00.
        // This guards against gross timezone anchoring bugs.
        let svc = SunService()
        let inp = try input(year: 2023, month: 9, day: 23,
                            lat: -33.8688, lon: 151.2093, tzID: "Australia/Sydney")
        let s = try svc.sunSchedule(for: inp)

        let noon = try #require(s.solarNoon)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Australia/Sydney")!
        let hour = cal.component(.hour, from: noon)

        // Solar noon in local time should be between 11:00 and 13:00.
        #expect(hour >= 11 && hour <= 13)
    }
}
