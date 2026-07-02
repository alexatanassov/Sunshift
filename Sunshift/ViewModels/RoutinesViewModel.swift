import Foundation

@Observable
final class RoutinesViewModel {
    private let store: RoutineStore
    private let subscriptionService: SubscriptionService
    private let sunService: SunService

    var routines: [LightRoutine] { store.routines }

    var canAddRoutine: Bool {
        subscriptionService.isPlusUser || routines.count < FreeTierLimits.maxActiveRoutines
    }

    var isAtFreeLimit: Bool {
        !subscriptionService.isPlusUser && routines.count >= FreeTierLimits.maxActiveRoutines
    }

    init(store: RoutineStore, subscriptionService: SubscriptionService, sunService: SunService = SunService()) {
        self.store = store
        self.subscriptionService = subscriptionService
        self.sunService = sunService
    }

    // MARK: - Upcoming routine

    struct UpcomingRoutinePreview: Equatable {
        let routineTitle: String
        let summary: String
        let countdownText: String
    }

    // Finds the soonest upcoming trigger across all enabled routines at `location`
    // and formats it for the countdown card. Returns nil when nothing is upcoming.
    func upcomingRoutinePreview(location: SavedLocation, now: Date = Date()) -> UpcomingRoutinePreview? {
        let nextTrigger = routines
            .compactMap { routine -> (LightRoutine, Date)? in
                guard let trigger = RoutineScheduler.nextTriggerDate(
                    for: routine,
                    sunService: sunService,
                    location: location,
                    after: now
                ) else { return nil }
                return (routine, trigger)
            }
            .min(by: { $0.1 < $1.1 })

        guard let (routine, trigger) = nextTrigger else { return nil }

        return UpcomingRoutinePreview(
            routineTitle: routine.title,
            summary: "\(triggerDescription(for: routine)), \(activeDaysSummary(for: routine))",
            countdownText: trigger.timeIntervalSince(now).formattedDuration
        )
    }

    // MARK: - Display helpers

    func triggerDescription(for routine: LightRoutine) -> String {
        let eventName = routine.sunEventType.displayName
        guard routine.offsetMinutes > 0 else {
            return "At \(eventName)"
        }
        let direction = routine.isBeforeEvent ? "before" : "after"
        return "\(offsetLabel(minutes: routine.offsetMinutes)) \(direction) \(eventName)"
    }

    func activeDaysSummary(for routine: LightRoutine) -> String {
        routine.selectedWeekdays.friendlyLabel
    }

    // MARK: - Mutations

    func addRoutine(_ routine: LightRoutine) {
        guard canAddRoutine else { return }
        store.add(routine)
    }

    func updateRoutine(_ routine: LightRoutine) {
        store.update(routine)
    }

    func toggleEnabled(for id: UUID) {
        store.toggleEnabled(id: id)
    }

    func deleteRoutine(id: UUID) {
        store.delete(id: id)
    }

    // Updates the first existing routine in place, or adds one when the store is empty.
    // Onboarding is the sole path that creates the first routine on a fresh install.
    func upsertOnboardingRoutine(_ routine: LightRoutine) {
        guard routines.isEmpty else {
            var existing = routines[0]
            existing.title = routine.title
            existing.templateType = routine.templateType
            existing.sunEventType = routine.sunEventType
            existing.offsetMinutes = routine.offsetMinutes
            existing.isBeforeEvent = routine.isBeforeEvent
            existing.selectedWeekdays = routine.selectedWeekdays
            existing.notificationMessage = routine.notificationMessage
            store.update(existing)
            return
        }
        store.add(routine)
    }

    // MARK: - Private

    private func offsetLabel(minutes: Int) -> String {
        guard minutes > 0 else { return "" }
        if minutes < 60 { return "\(minutes) min" }
        let hrs = minutes / 60
        let rem = minutes % 60
        if rem == 0 { return hrs == 1 ? "1 hr" : "\(hrs) hrs" }
        return "\(hrs) hr \(rem) min"
    }
}
