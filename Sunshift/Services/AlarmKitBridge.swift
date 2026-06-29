import Foundation
import AlarmKit

/// Centralizes all AlarmKit availability checks so callers (SunshiftApp, OnboardingView)
/// can use alarm scheduling without importing AlarmKit themselves.
@Observable
final class AlarmKitBridge {

    private let _permissionService: AnyObject?
    private let _scheduler: AnyObject?

    init() {
        if #available(iOS 26.0, *) {
            _permissionService = AlarmPermissionService()
            _scheduler = RoutineAlarmScheduler()
        } else {
            _permissionService = nil
            _scheduler = nil
        }
    }

    // MARK: - Availability-gated accessors

    @available(iOS 26.0, *)
    @available(macCatalyst, unavailable)
    var permissionService: AlarmPermissionService {
        _permissionService as! AlarmPermissionService
    }

    @available(iOS 26.0, *)
    @available(macCatalyst, unavailable)
    var scheduler: RoutineAlarmScheduler {
        _scheduler as! RoutineAlarmScheduler
    }

    // MARK: - Facade (no @available required at call site)

    var isAlarmKitAuthorized: Bool {
        if #available(iOS 26.0, *) {
            return permissionService.authorizationState == .authorized
        }
        return false
    }

    func rescheduleAll(_ routines: [LightRoutine], location: SavedLocation) async {
        if #available(iOS 26.0, *) {
            await scheduler.rescheduleAll(
                routines,
                location: location,
                authState: permissionService.authorizationState
            )
        }
    }

    func cancel(routineID: UUID) {
        if #available(iOS 26.0, *) {
            scheduler.cancel(routineID: routineID)
        }
    }

    func cancelAll(_ routines: [LightRoutine]) {
        if #available(iOS 26.0, *) {
            scheduler.cancelAll(routines)
        }
    }

    func requestAlarmPermission() async {
        if #available(iOS 26.0, *) {
            await permissionService.requestPermission()
        }
    }

    /// Returns an AsyncStream that emits Void whenever AlarmKit authorization state changes.
    /// SunshiftApp iterates this stream to trigger rescheduling without importing AlarmKit.
    func makeAuthorizationChangesStream() -> AsyncStream<Void> {
        AsyncStream { continuation in
            Task {
                if #available(iOS 26.0, *) {
                    for await _ in AlarmManager.shared.authorizationUpdates {
                        continuation.yield()
                    }
                }
                continuation.finish()
            }
        }
    }
}
