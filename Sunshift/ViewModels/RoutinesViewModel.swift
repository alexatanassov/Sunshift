import Foundation

@Observable
final class RoutinesViewModel {
    private let store: RoutineStore
    private let subscriptionService: SubscriptionService

    var routines: [LightRoutine] { store.routines }

    var canAddRoutine: Bool {
        subscriptionService.isPlusUser || routines.count < FreeTierLimits.maxActiveRoutines
    }

    var isAtFreeLimit: Bool {
        !subscriptionService.isPlusUser && routines.count >= FreeTierLimits.maxActiveRoutines
    }

    init(store: RoutineStore, subscriptionService: SubscriptionService) {
        self.store = store
        self.subscriptionService = subscriptionService
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
