import Testing
import Foundation
import AlarmKit
@testable import Sunshift

// MARK: - Mock

final class MockAlarmSchedulingCenter: AlarmSchedulingCenter, @unchecked Sendable {
    private(set) var scheduled: [(id: UUID, date: Date, title: String)] = []
    var authorizationState: AlarmManager.AuthorizationState = .authorized

    func schedule(id: UUID, date: Date, title: String) async throws {
        scheduled.append((id: id, date: date, title: title))
    }

    func cancel(id: UUID) {
        scheduled.removeAll { $0.id == id }
    }
}

// MARK: - Helpers

private func makeLocation(
    lat: Double = 37.7749,
    lon: Double = -122.4194,
    tzID: String = "America/Los_Angeles"
) -> SavedLocation {
    SavedLocation(
        name: "San Francisco",
        subtitle: "San Francisco, CA",
        latitude: lat,
        longitude: lon,
        timeZoneIdentifier: tzID,
        source: .manual,
        isCurrentLocation: false
    )
}

private func makeRoutine(
    title: String = "Sunset Walk",
    sunEventType: SunEventType = .sunset,
    offsetMinutes: Int = 0,
    isBeforeEvent: Bool = false,
    selectedWeekdays: WeekdaySelection = .everyday,
    isEnabled: Bool = true
) -> LightRoutine {
    LightRoutine(
        title: title,
        sunEventType: sunEventType,
        offsetMinutes: offsetMinutes,
        isBeforeEvent: isBeforeEvent,
        selectedWeekdays: selectedWeekdays,
        isEnabled: isEnabled
    )
}

private func makeDate(
    year: Int, month: Int, day: Int,
    hour: Int, minute: Int = 0,
    tzID: String = "America/Los_Angeles"
) throws -> Date {
    let tz = try #require(TimeZone(identifier: tzID))
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    var dc = DateComponents()
    dc.year = year; dc.month = month; dc.day = day
    dc.hour = hour; dc.minute = minute; dc.second = 0
    return try #require(cal.date(from: dc))
}

// MARK: - Tests

@MainActor
struct RoutineAlarmSchedulerTests {

    // MARK: - Authorized scheduling

    @Test func authorizedSchedulesSevenAlarmsForEverydayRoutine() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)

        await scheduler.scheduleOccurrences(
            for: makeRoutine(),
            location: makeLocation(),
            authState: .authorized,
            now: now
        )

        #expect(mock.scheduled.count == 7)
    }

    // MARK: - Permission gating

    @Test func deniedAuthSchedulesNone() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)

        await scheduler.scheduleOccurrences(
            for: makeRoutine(),
            location: makeLocation(),
            authState: .denied,
            now: now
        )

        #expect(mock.scheduled.isEmpty)
    }

    @Test func notDeterminedSchedulesNone() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)

        await scheduler.scheduleOccurrences(
            for: makeRoutine(),
            location: makeLocation(),
            authState: .notDetermined,
            now: now
        )

        #expect(mock.scheduled.isEmpty)
    }

    // MARK: - Disabled routine

    @Test func disabledRoutineCancelsAndSchedulesNone() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)
        let location = makeLocation()

        let routineID = UUID()
        let enabled = LightRoutine(id: routineID, title: "Walk", sunEventType: .sunset, offsetMinutes: 0, isEnabled: true)
        await scheduler.scheduleOccurrences(for: enabled, location: location, authState: .authorized, now: now)
        #expect(mock.scheduled.count == 7)

        scheduler.cancel(routineID: routineID)
        let disabled = LightRoutine(id: routineID, title: "Walk", sunEventType: .sunset, offsetMinutes: 0, isEnabled: false)
        await scheduler.scheduleOccurrences(for: disabled, location: location, authState: .authorized, now: now)

        #expect(mock.scheduled.isEmpty)
    }

    // MARK: - Cancel

    @Test func cancelRoutineRemovesSevenIDs() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)
        let routine = makeRoutine()

        await scheduler.scheduleOccurrences(for: routine, location: makeLocation(), authState: .authorized, now: now)
        #expect(mock.scheduled.count == 7)

        scheduler.cancel(routineID: routine.id)

        #expect(mock.scheduled.isEmpty)
    }

    @Test func cancelAllClearsCurrentRoutineAlarms() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)
        let location = makeLocation()

        let r1 = makeRoutine(title: "Morning")
        let r2 = makeRoutine(title: "Evening")
        await scheduler.rescheduleAll([r1, r2], location: location, authState: .authorized, now: now)
        #expect(mock.scheduled.count == 14)

        scheduler.cancelAll([r1, r2])

        #expect(mock.scheduled.isEmpty)
    }

    // MARK: - Deleted routine

    // rescheduleAll cancels only the alarms for routines in the provided array.
    // RoutinesView calls alarmKitBridge.cancel(routineID:) before deleteRoutine so the
    // routine's alarms are removed before it disappears from the store. This test
    // verifies that sequence leaves no orphan alarms.
    @Test func cancelRoutineBeforeDeletionLeavesNoOrphanAlarms() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)
        let location = makeLocation()
        let routine = makeRoutine()

        // Routine is active and fully scheduled.
        await scheduler.rescheduleAll([routine], location: location, authState: .authorized, now: now)
        #expect(mock.scheduled.count == 7)

        // Simulate the delete path: cancel before removing from store, then reschedule
        // with the now-empty array (as scheduleAll in SunshiftApp will do next).
        scheduler.cancel(routineID: routine.id)
        await scheduler.rescheduleAll([], location: location, authState: .authorized, now: now)

        let routineAlarmIDs = Set((0..<7).map { RoutineAlarmScheduler.alarmID(for: routine.id, occurrenceIndex: $0) })
        let remainingIDs = Set(mock.scheduled.map(\.id))
        #expect(remainingIDs.isDisjoint(with: routineAlarmIDs))
        #expect(mock.scheduled.isEmpty)
    }

    // MARK: - Identifier stability

    @Test func alarmIDsAreStableAndRoutineSpecific() {
        let id1 = UUID()
        let id2 = UUID()

        let first      = RoutineAlarmScheduler.alarmID(for: id1, occurrenceIndex: 0)
        let firstAgain = RoutineAlarmScheduler.alarmID(for: id1, occurrenceIndex: 0)
        let other      = RoutineAlarmScheduler.alarmID(for: id2, occurrenceIndex: 0)

        #expect(first == firstAgain)
        #expect(first != other)
    }

    @Test func alarmIDsFromDifferentRoutinesDontCollide() {
        let routineA = UUID()
        let routineB = UUID()

        let idsA = Set((0..<7).map { RoutineAlarmScheduler.alarmID(for: routineA, occurrenceIndex: $0) })
        let idsB = Set((0..<7).map { RoutineAlarmScheduler.alarmID(for: routineB, occurrenceIndex: $0) })

        #expect(idsA.isDisjoint(with: idsB))
    }

    // MARK: - Alarm content

    @Test func alarmTitleMatchesRoutineTitle() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)

        await scheduler.scheduleOccurrences(
            for: makeRoutine(title: "Evening Stroll"),
            location: makeLocation(),
            authState: .authorized,
            now: now
        )

        let entry = try #require(mock.scheduled.first)
        #expect(entry.title == "Evening Stroll")
    }

    // MARK: - No event in search window

    @Test func noEventInSearchWindowSchedulesNone() async throws {
        // Longyearbyen (Svalbard, 78.22 N) at midsummer: polar day means no sunset
        // across the entire 49-day search window.
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "Europe/Oslo")
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)
        let location = makeLocation(lat: 78.2232, lon: 15.6469, tzID: "Europe/Oslo")

        await scheduler.scheduleOccurrences(
            for: makeRoutine(sunEventType: .sunset, selectedWeekdays: .everyday),
            location: location,
            authState: .authorized,
            now: now
        )

        #expect(mock.scheduled.isEmpty)
    }

    // MARK: - rescheduleAll

    @Test func rescheduleAllSchedulesEnabledSkipsDisabled() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)
        let location = makeLocation()

        let enabled  = makeRoutine(title: "Enabled",  isEnabled: true)
        let disabled = makeRoutine(title: "Disabled", isEnabled: false)

        await scheduler.rescheduleAll([enabled, disabled], location: location, authState: .authorized, now: now)

        #expect(mock.scheduled.count == 7)
        #expect(mock.scheduled.allSatisfy { $0.title == "Enabled" })
    }

    // MARK: - Free-tier access

    @Test func freeTierStillSchedulesAlarmBecauseAlarmKitIsCoreFeature() async throws {
        // AlarmKit is NOT Plus-only. Free users with one allowed routine get alarm-style alerts.
        // RoutineAlarmScheduler has no subscription gate; authorization state is the only gate.
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockAlarmSchedulingCenter()
        let scheduler = RoutineAlarmScheduler(center: mock)

        await scheduler.scheduleOccurrences(
            for: makeRoutine(),
            location: makeLocation(),
            authState: .authorized,
            now: now
        )

        #expect(mock.scheduled.count == 7)
    }
}
