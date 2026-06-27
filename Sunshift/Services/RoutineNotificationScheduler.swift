import Foundation
import UserNotifications

// MARK: - Protocol

/// Abstracts UNUserNotificationCenter scheduling calls for testability.
protocol NotificationSchedulingCenter {
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func pendingNotificationRequests() async -> [UNNotificationRequest]
}

extension UNUserNotificationCenter: @retroactive NotificationSchedulingCenter {}

// MARK: - Scheduler

/// Schedules and cancels local notifications for light-based routines.
///
/// Each enabled routine gets up to 7 one-shot UNCalendarNotificationTrigger requests,
/// one per upcoming valid occurrence. Times shift daily as solar events shift, so
/// repeating triggers cannot represent them; we schedule a rolling window instead.
///
/// Call rescheduleAll on app launch and whenever routines or the active location change.
@MainActor
final class RoutineNotificationScheduler {

    private static let maxOccurrences = 7
    private static let maxDaysToSearch = 30

    private let center: any NotificationSchedulingCenter
    private let sunService: SunService

    init(
        center: any NotificationSchedulingCenter = UNUserNotificationCenter.current(),
        sunService: SunService = SunService()
    ) {
        self.center = center
        self.sunService = sunService
    }

    // MARK: - Stable identifier helpers

    static func notificationID(for routineID: UUID, occurrenceIndex: Int) -> String {
        "sunshift.routine.\(routineID.uuidString).\(occurrenceIndex)"
    }

    static func notificationIDPrefix(for routineID: UUID) -> String {
        "sunshift.routine.\(routineID.uuidString)."
    }

    // MARK: - Public API

    /// Cancels all pending requests for `routine`, then schedules the next
    /// `maxOccurrences` valid occurrences if the routine is enabled and permission allows.
    func schedule(
        _ routine: LightRoutine,
        location: SavedLocation,
        authStatus: UNAuthorizationStatus,
        now: Date = Date()
    ) async {
        await cancel(routineID: routine.id)

        guard routine.isEnabled else { return }
        guard authStatus == .authorized || authStatus == .provisional else { return }

        let dates = nextTriggerDates(for: routine, location: location, after: now)
        for (index, date) in dates.enumerated() {
            let request = makeRequest(for: routine, triggerDate: date, location: location, index: index)
            do {
                try await center.add(request)
            } catch {
                #if DEBUG
                print("[Sunshift] Notification scheduling failed -- \(routine.title) [\(index)]: \(error)")
                #endif
            }
        }
    }

    /// Cancels all pending notification requests whose identifiers start with this routine's prefix.
    func cancel(routineID: UUID) async {
        let prefix = Self.notificationIDPrefix(for: routineID)
        let pending = await center.pendingNotificationRequests()
        let ids = pending.compactMap { req in
            req.identifier.hasPrefix(prefix) ? req.identifier : nil
        }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Cancels and reschedules every routine in the array.
    func rescheduleAll(
        _ routines: [LightRoutine],
        location: SavedLocation,
        authStatus: UNAuthorizationStatus,
        now: Date = Date()
    ) async {
        for routine in routines {
            await schedule(routine, location: location, authStatus: authStatus, now: now)
        }
    }

    // MARK: - Private

    private func nextTriggerDates(
        for routine: LightRoutine,
        location: SavedLocation,
        after now: Date
    ) -> [Date] {
        let tz = TimeZone(identifier: location.timeZoneIdentifier) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        var results: [Date] = []

        for dayOffset in 0..<Self.maxDaysToSearch {
            guard results.count < Self.maxOccurrences else { break }
            guard let candidate = cal.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let startOfDay = cal.startOfDay(for: candidate)

            let weekday = cal.component(.weekday, from: startOfDay)
            guard routine.selectedWeekdays.contains(calendarWeekday: weekday) else { continue }

            let input = SunCalculationInput(
                date: startOfDay,
                latitude: location.latitude,
                longitude: location.longitude,
                timeZoneIdentifier: location.timeZoneIdentifier
            )
            guard let sunSchedule = try? sunService.sunSchedule(for: input) else { continue }
            guard let eventDate = sunSchedule.event(for: routine.sunEventType) else { continue }

            let offsetSeconds = TimeInterval(routine.offsetMinutes) * 60
            let trigger = routine.isBeforeEvent ? eventDate - offsetSeconds : eventDate + offsetSeconds

            if trigger > now {
                results.append(trigger)
            }
        }

        return results
    }

    private func makeRequest(
        for routine: LightRoutine,
        triggerDate: Date,
        location: SavedLocation,
        index: Int
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = routine.title
        content.body = routine.notificationMessage.isEmpty
            ? "It's time for your routine."
            : routine.notificationMessage
        content.sound = .default

        let tz = TimeZone(identifier: location.timeZoneIdentifier) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        components.timeZone = tz

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(
            identifier: Self.notificationID(for: routine.id, occurrenceIndex: index),
            content: content,
            trigger: trigger
        )
    }
}
