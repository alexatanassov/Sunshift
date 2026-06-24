import Testing
import Foundation
@testable import Sunshift

// MARK: - RoutineTemplate

struct RoutineTemplateTests {

    // MARK: Stable raw values

    @Test func sunsetWalkRawValue() {
        #expect(RoutineTemplate.sunsetWalk.rawValue == "sunset_walk")
    }

    @Test func morningLightRawValue() {
        #expect(RoutineTemplate.morningLight.rawValue == "morning_light")
    }

    @Test func windDownRawValue() {
        #expect(RoutineTemplate.windDown.rawValue == "wind_down")
    }

    @Test func goldenHourShootRawValue() {
        #expect(RoutineTemplate.goldenHourShoot.rawValue == "golden_hour_shoot")
    }

    @Test func customRawValue() {
        #expect(RoutineTemplate.custom.rawValue == "custom")
    }

    @Test func allCasesHaveExpectedCount() {
        #expect(RoutineTemplate.allCases.count == 5)
    }

    // MARK: Codable round-trip via raw value

    @Test func rawValueRoundTrip() {
        for template in RoutineTemplate.allCases {
            let restored = RoutineTemplate(rawValue: template.rawValue)
            #expect(restored == template)
        }
    }

    // MARK: Display names

    @Test func sunsetWalkDisplayName() {
        #expect(RoutineTemplate.sunsetWalk.displayName == "Sunset Walk")
    }

    @Test func morningLightDisplayName() {
        #expect(RoutineTemplate.morningLight.displayName == "Morning Light")
    }

    @Test func windDownDisplayName() {
        #expect(RoutineTemplate.windDown.displayName == "Wind Down")
    }

    @Test func goldenHourShootDisplayName() {
        #expect(RoutineTemplate.goldenHourShoot.displayName == "Golden Hour Shoot")
    }

    @Test func customDisplayName() {
        #expect(RoutineTemplate.custom.displayName == "Custom")
    }

    // MARK: Default sun event types

    @Test func sunsetWalkDefaultSunEvent() {
        #expect(RoutineTemplate.sunsetWalk.defaultSunEventType == .sunset)
    }

    @Test func morningLightDefaultSunEvent() {
        #expect(RoutineTemplate.morningLight.defaultSunEventType == .sunrise)
    }

    @Test func windDownDefaultSunEvent() {
        #expect(RoutineTemplate.windDown.defaultSunEventType == .sunset)
    }

    @Test func goldenHourShootDefaultSunEvent() {
        #expect(RoutineTemplate.goldenHourShoot.defaultSunEventType == .goldenHourStart)
    }

    @Test func customDefaultSunEvent() {
        #expect(RoutineTemplate.custom.defaultSunEventType == .sunset)
    }

    // MARK: Default offsets

    @Test func sunsetWalkDefaults() {
        #expect(RoutineTemplate.sunsetWalk.defaultOffsetMinutes == 30)
        #expect(RoutineTemplate.sunsetWalk.defaultIsBeforeEvent == true)
    }

    @Test func morningLightDefaults() {
        #expect(RoutineTemplate.morningLight.defaultOffsetMinutes == 15)
        #expect(RoutineTemplate.morningLight.defaultIsBeforeEvent == false)
    }

    @Test func windDownDefaults() {
        #expect(RoutineTemplate.windDown.defaultOffsetMinutes == 30)
        #expect(RoutineTemplate.windDown.defaultIsBeforeEvent == false)
    }

    @Test func goldenHourShootDefaults() {
        #expect(RoutineTemplate.goldenHourShoot.defaultOffsetMinutes == 10)
        #expect(RoutineTemplate.goldenHourShoot.defaultIsBeforeEvent == true)
    }

    @Test func customDefaults() {
        #expect(RoutineTemplate.custom.defaultOffsetMinutes == 0)
        #expect(RoutineTemplate.custom.defaultIsBeforeEvent == false)
    }

    // MARK: requiresPlus

    @Test func sunsetWalkIsFree() {
        #expect(RoutineTemplate.sunsetWalk.requiresPlus == false)
    }

    @Test func customIsFree() {
        #expect(RoutineTemplate.custom.requiresPlus == false)
    }

    @Test func morningLightRequiresPlus() {
        #expect(RoutineTemplate.morningLight.requiresPlus == true)
    }

    @Test func windDownRequiresPlus() {
        #expect(RoutineTemplate.windDown.requiresPlus == true)
    }

    @Test func goldenHourShootRequiresPlus() {
        #expect(RoutineTemplate.goldenHourShoot.requiresPlus == true)
    }
}

// MARK: - LightRoutine Codable

struct LightRoutineTests {

    @Test func codableRoundTrip() throws {
        let original = LightRoutine(
            id: UUID(),
            title: "Evening Walk",
            templateType: .sunsetWalk,
            sunEventType: .sunset,
            offsetMinutes: 30,
            isBeforeEvent: true,
            selectedWeekdays: .everyday,
            locationId: UUID(),
            isEnabled: true,
            notificationMessage: "Time for your sunset walk.",
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_000_000)
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LightRoutine.self, from: encoded)

        #expect(decoded == original)
        #expect(decoded.title == "Evening Walk")
        #expect(decoded.templateType == .sunsetWalk)
        #expect(decoded.sunEventType == .sunset)
        #expect(decoded.offsetMinutes == 30)
        #expect(decoded.isBeforeEvent == true)
        #expect(decoded.isEnabled == true)
    }

    @Test func codableRoundTripWithNilTemplate() throws {
        let original = LightRoutine(
            title: "My Routine",
            templateType: nil,
            sunEventType: .sunrise,
            offsetMinutes: 0
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LightRoutine.self, from: encoded)

        #expect(decoded == original)
        #expect(decoded.templateType == nil)
    }

    @Test func equatableDistinguishesDifferentRoutines() {
        let a = LightRoutine(title: "Walk", sunEventType: .sunset)
        let b = LightRoutine(title: "Run", sunEventType: .sunrise)
        #expect(a != b)
    }
}

// MARK: - WeekdaySelection

struct WeekdaySelectionTests {

    // MARK: contains(calendarWeekday:)

    @Test func sundayIsCalendarWeekday1() {
        #expect(WeekdaySelection.sunday.contains(calendarWeekday: 1))
        #expect(!WeekdaySelection.monday.contains(calendarWeekday: 1))
    }

    @Test func mondayIsCalendarWeekday2() {
        #expect(WeekdaySelection.monday.contains(calendarWeekday: 2))
        #expect(!WeekdaySelection.tuesday.contains(calendarWeekday: 2))
    }

    @Test func saturdayIsCalendarWeekday7() {
        #expect(WeekdaySelection.saturday.contains(calendarWeekday: 7))
        #expect(!WeekdaySelection.friday.contains(calendarWeekday: 7))
    }

    @Test func everydayContainsAllWeekdays() {
        for weekday in 1...7 {
            #expect(WeekdaySelection.everyday.contains(calendarWeekday: weekday))
        }
    }

    @Test func weekdaysDoesNotContainWeekends() {
        // weekdays = Mon-Fri: calendar weekdays 2-6
        #expect(WeekdaySelection.weekdays.contains(calendarWeekday: 2))
        #expect(WeekdaySelection.weekdays.contains(calendarWeekday: 6))
        #expect(!WeekdaySelection.weekdays.contains(calendarWeekday: 1))
        #expect(!WeekdaySelection.weekdays.contains(calendarWeekday: 7))
    }

    @Test func weekendsContainsOnlySaturdayAndSunday() {
        #expect(WeekdaySelection.weekends.contains(calendarWeekday: 1))
        #expect(WeekdaySelection.weekends.contains(calendarWeekday: 7))
        #expect(!WeekdaySelection.weekends.contains(calendarWeekday: 2))
        #expect(!WeekdaySelection.weekends.contains(calendarWeekday: 6))
    }

    @Test func outOfRangeWeekdayReturnsFalse() {
        #expect(!WeekdaySelection.everyday.contains(calendarWeekday: 0))
        #expect(!WeekdaySelection.everyday.contains(calendarWeekday: 8))
    }

    // MARK: friendlyLabel

    @Test func everydayLabel() {
        #expect(WeekdaySelection.everyday.friendlyLabel == "Every day")
    }

    @Test func weekdaysLabel() {
        #expect(WeekdaySelection.weekdays.friendlyLabel == "Weekdays")
    }

    @Test func weekendsLabel() {
        #expect(WeekdaySelection.weekends.friendlyLabel == "Weekends")
    }

    @Test func customSelectionLabel() {
        let monWedFri: WeekdaySelection = [.monday, .wednesday, .friday]
        #expect(monWedFri.friendlyLabel == "Mon, Wed, Fri")
    }

    @Test func emptySelectionLabel() {
        let empty = WeekdaySelection(rawValue: 0)
        #expect(empty.friendlyLabel == "Never")
    }
}

// MARK: - SunSchedule event(for:)

struct SunScheduleEventLookupTests {

    private func makeSchedule() throws -> SunSchedule {
        let svc = SunService()
        let tz = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var dc = DateComponents()
        dc.year = 2026; dc.month = 6; dc.day = 21
        dc.hour = 12; dc.minute = 0; dc.second = 0
        let date = try #require(cal.date(from: dc))
        let input = SunCalculationInput(
            date: date,
            latitude: 37.7749,
            longitude: -122.4194,
            timeZoneIdentifier: "America/Los_Angeles"
        )
        return try svc.sunSchedule(for: input)
    }

    @Test func eventForSunriseMatchesSunrise() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .sunrise) == s.sunrise)
        #expect(s.event(for: .sunrise) != nil)
    }

    @Test func eventForSunsetMatchesSunset() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .sunset) == s.sunset)
        #expect(s.event(for: .sunset) != nil)
    }

    @Test func eventForSolarNoonMatchesSolarNoon() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .solarNoon) == s.solarNoon)
    }

    @Test func eventForGoldenHourStartMatchesField() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .goldenHourStart) == s.goldenHourStart)
    }

    @Test func eventForGoldenHourEndMatchesField() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .goldenHourEnd) == s.goldenHourEnd)
    }

    @Test func eventForBlueHourStartMatchesField() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .blueHourStart) == s.blueHourStart)
    }

    @Test func eventForBlueHourEndMatchesField() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .blueHourEnd) == s.blueHourEnd)
    }

    @Test func eventForFirstLightMatchesField() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .firstLight) == s.firstLight)
    }

    @Test func eventForLastLightMatchesField() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .lastLight) == s.lastLight)
    }

    @Test func eventForDaylightRemainingReturnsNil() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .daylightRemaining) == nil)
    }

    @Test func eventForCivilTwilightStartMatchesField() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .civilTwilightStart) == s.civilTwilightStart)
    }

    @Test func eventForCivilTwilightEndMatchesField() throws {
        let s = try makeSchedule()
        #expect(s.event(for: .civilTwilightEnd) == s.civilTwilightEnd)
    }
}
