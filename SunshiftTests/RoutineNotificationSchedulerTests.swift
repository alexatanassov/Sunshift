import Testing
import Foundation
import UserNotifications
@testable import Sunshift

// MARK: - Mock

/// In-memory stand-in for UNUserNotificationCenter.
/// Marked @unchecked Sendable because all mutating calls originate from the
/// @MainActor-isolated RoutineNotificationScheduler, so no concurrent access occurs.
private final class MockNotificationCenter: NotificationSchedulingCenter, @unchecked Sendable {
    private(set) var pending: [UNNotificationRequest] = []

    func add(_ request: UNNotificationRequest) async throws {
        pending.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        pending.removeAll { identifiers.contains($0.identifier) }
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        pending
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
    isEnabled: Bool = true,
    notificationMessage: String = ""
) -> LightRoutine {
    LightRoutine(
        title: title,
        sunEventType: sunEventType,
        offsetMinutes: offsetMinutes,
        isBeforeEvent: isBeforeEvent,
        selectedWeekdays: selectedWeekdays,
        isEnabled: isEnabled,
        notificationMessage: notificationMessage
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

/// Tests run on the main actor to match RoutineNotificationScheduler's isolation.
@MainActor
struct RoutineNotificationSchedulerTests {

    // MARK: - Rolling window count

    @Test func authorizedEnabledRoutineSchedulesSevenOccurrences() async throws {
        // Noon in SF — today's sunset is still hours away, giving us 7 days of sunsets.
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)

        await scheduler.schedule(makeRoutine(), location: makeLocation(), authStatus: .authorized, now: now)

        #expect(mock.pending.count == 7)
    }

    // MARK: - Permission gating

    @Test func deniedPermissionCancelsExistingAndSchedulesNone() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)
        let routine = makeRoutine()
        let location = makeLocation()

        // Pre-schedule to populate the mock.
        await scheduler.schedule(routine, location: location, authStatus: .authorized, now: now)
        #expect(mock.pending.count == 7)

        // Re-schedule with denied permission; prior requests should be removed.
        await scheduler.schedule(routine, location: location, authStatus: .denied, now: now)

        #expect(mock.pending.isEmpty)
    }

    @Test func notDeterminedPermissionSchedulesNone() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)

        await scheduler.schedule(makeRoutine(), location: makeLocation(), authStatus: .notDetermined, now: now)

        #expect(mock.pending.isEmpty)
    }

    @Test func provisionalPermissionSchedulesSeven() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)

        await scheduler.schedule(makeRoutine(), location: makeLocation(), authStatus: .provisional, now: now)

        #expect(mock.pending.count == 7)
    }

    // MARK: - Disabled routine

    @Test func disabledRoutineCancelsExistingAndSchedulesNone() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)
        let location = makeLocation()

        let routineID = UUID()
        let enabled = LightRoutine(
            id: routineID,
            title: "Sunset Walk",
            sunEventType: .sunset,
            offsetMinutes: 0,
            isEnabled: true
        )
        await scheduler.schedule(enabled, location: location, authStatus: .authorized, now: now)
        #expect(mock.pending.count == 7)

        let disabled = LightRoutine(
            id: routineID,
            title: "Sunset Walk",
            sunEventType: .sunset,
            offsetMinutes: 0,
            isEnabled: false
        )
        await scheduler.schedule(disabled, location: location, authStatus: .authorized, now: now)

        #expect(mock.pending.isEmpty)
    }

    // MARK: - Cancel

    @Test func cancelRemovesAllOccurrencesWithRoutinePrefix() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)
        let routine = makeRoutine()
        let location = makeLocation()

        await scheduler.schedule(routine, location: location, authStatus: .authorized, now: now)
        #expect(!mock.pending.isEmpty)

        let prefix = RoutineNotificationScheduler.notificationIDPrefix(for: routine.id)
        #expect(mock.pending.allSatisfy { $0.identifier.hasPrefix(prefix) })

        await scheduler.cancel(routineID: routine.id)

        #expect(mock.pending.isEmpty)
    }

    // MARK: - rescheduleAll

    @Test func rescheduleAllSchedulesEnabledSkipsDisabled() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)
        let location = makeLocation()

        let enabled = makeRoutine(title: "Enabled", isEnabled: true)
        let disabled = makeRoutine(title: "Disabled", isEnabled: false)

        await scheduler.rescheduleAll([enabled, disabled], location: location, authStatus: .authorized, now: now)

        #expect(mock.pending.count == 7)

        let prefix = RoutineNotificationScheduler.notificationIDPrefix(for: enabled.id)
        #expect(mock.pending.allSatisfy { $0.identifier.hasPrefix(prefix) })
    }

    // MARK: - Identifier stability

    @Test func notificationIDsAreStableAndRoutineSpecific() {
        let id1 = UUID()
        let id2 = UUID()

        let first      = RoutineNotificationScheduler.notificationID(for: id1, occurrenceIndex: 0)
        let firstAgain = RoutineNotificationScheduler.notificationID(for: id1, occurrenceIndex: 0)
        let other      = RoutineNotificationScheduler.notificationID(for: id2, occurrenceIndex: 0)
        let prefix     = RoutineNotificationScheduler.notificationIDPrefix(for: id1)

        #expect(first == firstAgain)
        #expect(first != other)
        #expect(first.hasPrefix(prefix))
        #expect(!other.hasPrefix(prefix))
    }

    // MARK: - Notification content

    @Test func emptyMessageUsesDefaultBody() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)

        await scheduler.schedule(
            makeRoutine(notificationMessage: ""),
            location: makeLocation(),
            authStatus: .authorized,
            now: now
        )

        let request = try #require(mock.pending.first)
        #expect(request.content.body == "It's time for your routine.")
    }

    @Test func customMessageIsUsed() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)

        await scheduler.schedule(
            makeRoutine(notificationMessage: "Time for your walk."),
            location: makeLocation(),
            authStatus: .authorized,
            now: now
        )

        let request = try #require(mock.pending.first)
        #expect(request.content.body == "Time for your walk.")
    }

    @Test func titleMatchesRoutineTitle() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)

        await scheduler.schedule(
            makeRoutine(title: "Evening Stroll"),
            location: makeLocation(),
            authStatus: .authorized,
            now: now
        )

        let request = try #require(mock.pending.first)
        #expect(request.content.title == "Evening Stroll")
    }

    // MARK: - Trigger type

    @Test func triggerIsCalendarTrigger() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)

        await scheduler.schedule(makeRoutine(), location: makeLocation(), authStatus: .authorized, now: now)

        let request = try #require(mock.pending.first)
        #expect(request.trigger is UNCalendarNotificationTrigger)
    }

    @Test func triggerComponentsUseLocationTimezone() async throws {
        // Sunset in SF on this date is in the evening (after 6 PM PDT).
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)
        let location = makeLocation(tzID: "America/Los_Angeles")

        await scheduler.schedule(
            makeRoutine(sunEventType: .sunset, offsetMinutes: 0),
            location: location,
            authStatus: .authorized,
            now: now
        )

        let request = try #require(mock.pending.first)
        let calTrigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        let expectedTZ = try #require(TimeZone(identifier: "America/Los_Angeles"))

        #expect(calTrigger.dateComponents.timeZone == expectedTZ)
        let hour = try #require(calTrigger.dateComponents.hour)
        #expect(hour >= 18)  // sunset in SF in late June is after 6 PM local time
    }

    // MARK: - Deleted routine

    @Test func rescheduleAllClearsStaleNotificationsForDeletedRoutine() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)
        let location = makeLocation()

        let routineA = makeRoutine(title: "Morning Light")
        let routineB = makeRoutine(title: "Sunset Walk")

        await scheduler.rescheduleAll([routineA, routineB], location: location, authStatus: .authorized, now: now)
        #expect(mock.pending.count == 14)

        // Simulate deletion of routineB.
        await scheduler.rescheduleAll([routineA], location: location, authStatus: .authorized, now: now)

        #expect(mock.pending.count == 7)
        let prefixA = RoutineNotificationScheduler.notificationIDPrefix(for: routineA.id)
        #expect(mock.pending.allSatisfy { $0.identifier.hasPrefix(prefixA) })
    }

    // MARK: - cancelAll

    @Test func cancelAllRemovesAllSunshiftNotifications() async throws {
        let now = try makeDate(year: 2026, month: 6, day: 23, hour: 12)
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)
        let location = makeLocation()

        let routineA = makeRoutine(title: "Morning")
        let routineB = makeRoutine(title: "Evening")
        await scheduler.rescheduleAll([routineA, routineB], location: location, authStatus: .authorized, now: now)
        #expect(mock.pending.count == 14)

        await scheduler.cancelAll()

        #expect(mock.pending.isEmpty)
    }

    // MARK: - Unavailable event

    @Test func noEventInSearchWindowSchedulesNone() async throws {
        // Longyearbyen (Svalbard, 78.22°N) at midsummer: polar day extends ~63 days past
        // June 21, covering the entire 49-day search window (maxOccurrences × 7 days).
        let now = try makeDate(year: 2026, month: 6, day: 21, hour: 12, tzID: "Europe/Oslo")
        let mock = MockNotificationCenter()
        let scheduler = RoutineNotificationScheduler(center: mock)
        let location = makeLocation(lat: 78.2232, lon: 15.6469, tzID: "Europe/Oslo")

        await scheduler.schedule(
            makeRoutine(sunEventType: .sunset, selectedWeekdays: .everyday),
            location: location,
            authStatus: .authorized,
            now: now
        )

        #expect(mock.pending.isEmpty)
    }
}
