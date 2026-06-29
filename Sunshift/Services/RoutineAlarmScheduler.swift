import Foundation
import SwiftUI
import AlarmKit

// MARK: - Metadata

@available(iOS 26.0, *)
@available(macCatalyst, unavailable)
struct SunshiftAlarmMetadata: AlarmMetadata {}

// MARK: - Protocol

@available(iOS 26.0, *)
@available(macCatalyst, unavailable)
protocol AlarmSchedulingCenter {
    func schedule(id: UUID, date: Date, title: String) async throws
    func cancel(id: UUID)
    var authorizationState: AlarmManager.AuthorizationState { get }
}

// MARK: - Live implementation

@available(iOS 26.0, *)
@available(macCatalyst, unavailable)
final class LiveAlarmSchedulingCenter: AlarmSchedulingCenter {

    func schedule(id: UUID, date: Date, title: String) async throws {
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            secondaryButton: nil,
            secondaryButtonBehavior: nil
        )
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes<SunshiftAlarmMetadata>(
            presentation: presentation,
            metadata: SunshiftAlarmMetadata(),
            tintColor: .orange
        )
        let config = AlarmManager.AlarmConfiguration<SunshiftAlarmMetadata>.alarm(
            schedule: .fixed(date),
            attributes: attributes
        )
        _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
    }

    func cancel(id: UUID) {
        try? AlarmManager.shared.cancel(id: id)
    }

    var authorizationState: AlarmManager.AuthorizationState {
        AlarmManager.shared.authorizationState
    }
}

// MARK: - Scheduler

@available(iOS 26.0, *)
@available(macCatalyst, unavailable)
@MainActor
final class RoutineAlarmScheduler {

    private static let maxOccurrences = 7
    // 7 weeks guarantees 7 occurrences even for once-weekly routines.
    private static let maxDaysToSearch = maxOccurrences * 7

    private let center: any AlarmSchedulingCenter
    private let sunService: SunService

    init(
        center: (any AlarmSchedulingCenter)? = nil,
        sunService: SunService? = nil
    ) {
        self.center = center ?? LiveAlarmSchedulingCenter()
        self.sunService = sunService ?? SunService()
    }

    // MARK: - Stable identifier helpers

    /// Returns a deterministic UUID derived from routineID + occurrenceIndex.
    /// The first 14 bytes come from routineID; bytes 14–15 encode the index.
    static func alarmID(for routineID: UUID, occurrenceIndex: Int) -> UUID {
        let src = routineID.uuid
        return UUID(uuid: (
            src.0, src.1, src.2, src.3, src.4, src.5, src.6, src.7,
            src.8, src.9, src.10, src.11, src.12, src.13,
            UInt8((occurrenceIndex >> 8) & 0xFF),
            UInt8(occurrenceIndex & 0xFF)
        ))
    }

    // MARK: - Cancel

    func cancel(routineID: UUID) {
        for index in 0..<Self.maxOccurrences {
            center.cancel(id: Self.alarmID(for: routineID, occurrenceIndex: index))
        }
    }

    func cancelAll(_ routines: [LightRoutine]) {
        for routine in routines {
            cancel(routineID: routine.id)
        }
    }

    // MARK: - Schedule

    /// Schedules up to 7 alarm occurrences for the routine.
    /// Does not cancel prior occurrences — callers are responsible for cancellation before calling.
    func scheduleOccurrences(
        for routine: LightRoutine,
        location: SavedLocation,
        authState: AlarmManager.AuthorizationState,
        now: Date
    ) async {
        guard authState == .authorized else { return }
        guard routine.isEnabled else { return }

        let dates = nextTriggerDates(for: routine, location: location, after: now)
        for (index, date) in dates.enumerated() {
            let id = Self.alarmID(for: routine.id, occurrenceIndex: index)
            do {
                try await center.schedule(id: id, date: date, title: routine.title)
            } catch {
                #if DEBUG
                print("[Sunshift] Alarm scheduling failed -- \(routine.title) [\(index)]: \(error)")
                #endif
            }
        }
    }

    /// Cancels all alarms for the provided routines then reschedules enabled ones.
    ///
    /// Note: alarms for routines not present in the array (e.g. deleted routines) are not
    /// cancelled here. Call cancel(routineID:) explicitly when removing a routine.
    func rescheduleAll(
        _ routines: [LightRoutine],
        location: SavedLocation,
        authState: AlarmManager.AuthorizationState,
        now: Date = Date()
    ) async {
        cancelAll(routines)
        guard authState == .authorized else { return }
        for routine in routines {
            await scheduleOccurrences(for: routine, location: location, authState: authState, now: now)
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
}
