import Testing
import Foundation
@testable import Sunshift

// MARK: - Helpers

private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0,
                      tzID: String) throws -> Date {
    let tz = try #require(TimeZone(identifier: tzID))
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    var dc = DateComponents()
    dc.year = year; dc.month = month; dc.day = day
    dc.hour = hour; dc.minute = minute; dc.second = 0
    return try #require(cal.date(from: dc))
}

private func makeSavedLocation(
    name: String = "Test City",
    latitude: Double = 37.7749,
    longitude: Double = -122.4194,
    tzID: String = "America/Los_Angeles",
    source: LocationSource = .manual,
    isCurrentLocation: Bool = false
) -> SavedLocation {
    SavedLocation(
        name: name,
        subtitle: "\(name), CA",
        latitude: latitude,
        longitude: longitude,
        timeZoneIdentifier: tzID,
        source: source,
        isCurrentLocation: isCurrentLocation
    )
}

// MARK: - TimeInterval.formattedCountdown

struct FormattedCountdownTests {

    @Test func underOneMinuteReturnsStartingNow() {
        let interval: TimeInterval = 30
        #expect(interval.formattedCountdown == "starting now")
    }

    @Test func exactlyOneMinuteShowsIn1m() {
        let interval: TimeInterval = 60
        #expect(interval.formattedCountdown == "in 1m")
    }

    @Test func fortyFiveMinutesShowsIn45m() {
        let interval: TimeInterval = 45 * 60
        #expect(interval.formattedCountdown == "in 45m")
    }

    @Test func oneHourTwentyMinutesShowsIn1h20m() {
        let interval: TimeInterval = (1 * 60 + 20) * 60
        #expect(interval.formattedCountdown == "in 1h 20m")
    }

    @Test func twoHoursFourteenMinutesShowsIn2h14m() {
        let interval: TimeInterval = (2 * 60 + 14) * 60
        #expect(interval.formattedCountdown == "in 2h 14m")
    }

    @Test func negativeIntervalReturnsStartingNow() {
        let interval: TimeInterval = -100
        #expect(interval.formattedCountdown == "starting now")
    }
}

// MARK: - TodayViewModel

struct TodayViewModelTests {

    // MARK: Location kind

    @Test func locationKind_fallback_whenIsUsingFallback() {
        let vm = TodayViewModel()
        let location = SavedLocation.devFallback
        vm.refresh(location: location, isUsingFallback: true, now: Date())
        #expect(vm.locationKind == .fallback)
    }

    @Test func locationKind_current_whenIsCurrentLocation() {
        let vm = TodayViewModel()
        let location = makeSavedLocation(source: .current, isCurrentLocation: true)
        vm.refresh(location: location, isUsingFallback: false, now: Date())
        #expect(vm.locationKind == .current)
    }

    @Test func locationKind_saved_whenManualLocationAndNotFallback() {
        let vm = TodayViewModel()
        let location = makeSavedLocation(source: .manual, isCurrentLocation: false)
        vm.refresh(location: location, isUsingFallback: false, now: Date())
        #expect(vm.locationKind == .saved)
    }

    // MARK: Location display

    @Test func locationDisplayName_matchesLocationName() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation(name: "San Francisco")
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.locationDisplayName == "San Francisco")
    }

    // MARK: Schedule population

    @Test func sunriseText_nonEmptyForMidLatitudeSummer() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 6, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.sunriseText != "--")
        #expect(vm.schedule != nil)
    }

    @Test func sunsetText_nonEmptyForMidLatitudeSummer() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 6, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.sunsetText != "--")
    }

    @Test func solarNoonText_nonEmptyForMidLatitudeSummer() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 6, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.solarNoonText != "--")
    }

    @Test func goldenHourText_mapsToEveningGoldenHourStart() throws {
        // goldenHourText should reflect schedule.goldenHourEnd (start of evening golden hour window)
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let tz = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 6, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)

        let expected = vm.schedule?.goldenHourEnd.map { $0.formattedTime(in: tz) } ?? "--"
        #expect(vm.goldenHourText == expected)
        #expect(vm.goldenHourText != "--")
    }

    @Test func lastLightText_nonEmptyForMidLatitudeSummer() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 6, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.lastLightText != "--")
    }

    // MARK: Polar conditions

    @Test func sunriseText_dashesForPolarDay() throws {
        // Tromsø in summer: no sunrise/sunset
        let vm = TodayViewModel()
        let location = makeSavedLocation(
            latitude: 69.6492, longitude: 18.9553, tzID: "Europe/Oslo"
        )
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "Europe/Oslo")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.sunriseText == "--")
        #expect(vm.sunsetText == "--")
        #expect(vm.errorMessage == nil)
    }

    // MARK: Daylight remaining

    @Test func daylightRemainingText_presentBeforeSunset() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 14, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.daylightRemainingText != nil)
    }

    @Test func daylightRemainingText_nilAfterSunset() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 22, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.daylightRemainingText == nil)
    }

    // MARK: Next event

    @Test func nextEventTitle_presentAtMorning() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 5, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.nextEventTitle != nil)
    }

    @Test func nextEventCountdownText_presentAtMorning() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 5, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.nextEventCountdownText != nil)
    }

    @Test func nextEventCountdownText_fallsBackToTomorrowAfterAllEventsPass() throws {
        // At 23:59 local, today's events are exhausted; tomorrow's first event should be returned.
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 23, minute: 59,
                               tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.nextEventTitle != nil)
        #expect(vm.nextEventCountdownText != nil)
    }

    // MARK: Error state

    @Test func errorMessage_nilOnValidLocation() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.errorMessage == nil)
    }

    @Test func errorMessage_setOnInvalidCoordinates() {
        let vm = TodayViewModel()
        let badLocation = makeSavedLocation(latitude: 200, longitude: 0)
        vm.refresh(location: badLocation, isUsingFallback: false, now: Date())
        #expect(vm.errorMessage != nil)
        #expect(vm.schedule == nil)
        #expect(vm.sunriseText == "--")
        #expect(vm.sunsetText == "--")
    }

    // MARK: Repeated refresh

    // MARK: Polar state

    @Test func isPolarDay_trueForHighLatitudeSummer() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation(latitude: 69.6492, longitude: 18.9553, tzID: "Europe/Oslo")
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "Europe/Oslo")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.isPolarDay == true)
        #expect(vm.isPolarNight == false)
        #expect(vm.errorMessage == nil)
    }

    @Test func isPolarDay_falseForMidLatitudeSummer() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.isPolarDay == false)
        #expect(vm.isPolarNight == false)
    }

    // MARK: hasRefreshed

    @Test func hasRefreshed_falseBeforeRefresh() {
        let vm = TodayViewModel()
        #expect(vm.hasRefreshed == false)
    }

    @Test func hasRefreshed_trueAfterSuccessfulRefresh() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.hasRefreshed == true)
    }

    @Test func hasRefreshed_trueAfterFailedRefresh() {
        let vm = TodayViewModel()
        let badLocation = makeSavedLocation(latitude: 200, longitude: 0)
        vm.refresh(location: badLocation, isUsingFallback: false, now: Date())
        #expect(vm.hasRefreshed == true)
        #expect(vm.errorMessage != nil)
    }

    // MARK: - Routine state

    @Test func hasNextRoutine_falseWhenNoEnabledRoutine() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, enabledRoutine: nil, now: now)
        #expect(vm.hasNextRoutine == false)
        #expect(vm.nextRoutineName == "")
        #expect(vm.nextRoutineTimeText == "")
    }

    @Test func hasNextRoutine_trueWhenEnabledRoutineExists() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        let routine = LightRoutine(
            title: "Sunset Walk",
            sunEventType: .sunset,
            offsetMinutes: 30,
            isBeforeEvent: true,
            selectedWeekdays: .everyday,
            isEnabled: true
        )
        vm.refresh(location: location, isUsingFallback: false, enabledRoutine: routine, now: now)
        #expect(vm.hasNextRoutine == true)
    }

    @Test func nextRoutineName_matchesEnabledRoutineTitle() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        let routine = LightRoutine(
            title: "Evening Stroll",
            sunEventType: .sunset,
            offsetMinutes: 0,
            isBeforeEvent: false,
            selectedWeekdays: .everyday,
            isEnabled: true
        )
        vm.refresh(location: location, isUsingFallback: false, enabledRoutine: routine, now: now)
        #expect(vm.nextRoutineName == "Evening Stroll")
    }

    @Test func nextRoutineTimeText_nonEmptyWhenSchedulerFindsTime() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        // Noon — sunset trigger is still ahead
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        let routine = LightRoutine(
            title: "Sunset Walk",
            sunEventType: .sunset,
            offsetMinutes: 30,
            isBeforeEvent: true,
            selectedWeekdays: .everyday,
            isEnabled: true
        )
        vm.refresh(location: location, isUsingFallback: false, enabledRoutine: routine, now: now)
        #expect(vm.nextRoutineTimeText != "")
        #expect(vm.nextRoutineTimeText != "Not available today")
    }

    @Test func nextRoutineTimeText_placeholderWhenSchedulerReturnsNil() throws {
        let vm = TodayViewModel()
        // Tromsø in midsummer: no sunset event
        let location = makeSavedLocation(latitude: 69.6492, longitude: 18.9553, tzID: "Europe/Oslo")
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "Europe/Oslo")
        let routine = LightRoutine(
            title: "Sunset Walk",
            sunEventType: .sunset,
            offsetMinutes: 30,
            isBeforeEvent: true,
            selectedWeekdays: .everyday,
            isEnabled: true
        )
        vm.refresh(location: location, isUsingFallback: false, enabledRoutine: routine, now: now)
        #expect(vm.hasNextRoutine == true)
        #expect(vm.nextRoutineTimeText == "Not available today")
    }

    @Test func nextRoutineTriggerText_nonEmptyForOffsetRoutine() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        let routine = LightRoutine(
            title: "Sunset Walk",
            sunEventType: .sunset,
            offsetMinutes: 30,
            isBeforeEvent: true,
            selectedWeekdays: .everyday,
            isEnabled: true
        )
        vm.refresh(location: location, isUsingFallback: false, enabledRoutine: routine, now: now)
        #expect(vm.nextRoutineTriggerText == "30 min before Sunset")
    }

    @Test func nextRoutineTriggerText_atEventWhenOffsetIsZero() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        let routine = LightRoutine(
            title: "Solar Noon",
            sunEventType: .solarNoon,
            offsetMinutes: 0,
            isBeforeEvent: false,
            selectedWeekdays: .everyday,
            isEnabled: true
        )
        vm.refresh(location: location, isUsingFallback: false, enabledRoutine: routine, now: now)
        #expect(vm.nextRoutineTriggerText == "At Solar Noon")
    }

    @Test func disabledRoutineIgnoredWhenNilPassedToVM() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        // Caller is responsible for filtering; pass nil to simulate no enabled routine
        vm.refresh(location: location, isUsingFallback: false, enabledRoutine: nil, now: now)
        #expect(vm.hasNextRoutine == false)
        #expect(vm.nextRoutineName == "")
    }

    // MARK: - Week preview

    @Test func weekPreview_hasSevenDaysForNormalLocation() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.weekPreview.count == 7)
    }

    @Test func weekPreview_firstDayMatchesTodaysLocalDate() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        let tz = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let first = try #require(vm.weekPreview.first)
        #expect(cal.isDate(first.date, inSameDayAs: now))
    }

    @Test func weekPreview_allDaysHaveSunriseForMidLatitudeSummer() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.weekPreview.count == 7)
        #expect(vm.weekPreview.allSatisfy { $0.sunrise != nil })
        #expect(vm.weekPreview.allSatisfy { $0.sunset != nil })
    }

    @Test func weekPreview_emptyAfterInvalidCoordinates() {
        let vm = TodayViewModel()
        let badLocation = makeSavedLocation(latitude: 200, longitude: 0)
        vm.refresh(location: badLocation, isUsingFallback: false, now: Date())
        #expect(vm.weekPreview.isEmpty)
        #expect(vm.errorMessage != nil)
    }

    // MARK: Repeated refresh

    @Test func secondRefresh_clearsStaleSchedule() throws {
        let vm = TodayViewModel()
        let location = makeSavedLocation()
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "America/Los_Angeles")
        vm.refresh(location: location, isUsingFallback: false, now: now)
        #expect(vm.schedule != nil)

        // Refresh with invalid coords triggers error and clears schedule
        let badLocation = makeSavedLocation(latitude: 200, longitude: 0)
        vm.refresh(location: badLocation, isUsingFallback: false, now: now)
        #expect(vm.schedule == nil)
        #expect(vm.errorMessage != nil)
    }
}
