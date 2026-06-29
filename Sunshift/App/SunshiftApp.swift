import SwiftUI

@main
struct SunshiftApp: App {
    @State private var appState = AppState()
    @State private var subscriptionService: SubscriptionService
    @State private var locationViewModel: LocationViewModel
    @State private var routineStore: RoutineStore
    @State private var routinesViewModel: RoutinesViewModel
    @State private var notificationPermissionService = NotificationPermissionService()
    private let notificationScheduler = RoutineNotificationScheduler()
    private let alarmKitBridge = AlarmKitBridge()

    init() {
        let sub = SubscriptionService()
        let store = RoutineStore()
        _subscriptionService = State(wrappedValue: sub)
        _locationViewModel = State(wrappedValue: LocationViewModel(subscriptionService: sub))
        _routineStore = State(wrappedValue: store)
        _routinesViewModel = State(wrappedValue: RoutinesViewModel(store: store, subscriptionService: sub))
    }

    var body: some Scene {
        WindowGroup {
            SunshiftRootView()
                .environment(appState)
                .environment(subscriptionService)
                .environment(locationViewModel)
                .environment(routineStore)
                .environment(routinesViewModel)
                .environment(notificationPermissionService)
                .environment(alarmKitBridge)
                .onAppear { locationViewModel.loadInitialLocation() }
                .task { await scheduleAll() }
                .task {
                    for await _ in alarmKitBridge.makeAuthorizationChangesStream() {
                        await scheduleAll()
                    }
                }
                .onChange(of: routineStore.routines) {
                    Task { await scheduleAll() }
                }
                .onChange(of: locationViewModel.resolvedLocation.id) {
                    Task { await scheduleAll() }
                }
                .onChange(of: notificationPermissionService.authorizationStatus.rawValue) {
                    Task { await scheduleAll() }
                }
        }
    }

    private func scheduleAll() async {
        if alarmKitBridge.isAlarmKitAuthorized {
            await alarmKitBridge.rescheduleAll(
                routineStore.routines,
                location: locationViewModel.resolvedLocation
            )
            await notificationScheduler.cancelAll()
            return
        }
        // Cancel any stale AlarmKit alarms from a prior authorized session, then fall back to notifications.
        alarmKitBridge.cancelAll(routineStore.routines)
        await notificationScheduler.rescheduleAll(
            routineStore.routines,
            location: locationViewModel.resolvedLocation,
            authStatus: notificationPermissionService.authorizationStatus
        )
    }
}
