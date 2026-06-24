import SwiftUI

@main
struct SunshiftApp: App {
    @State private var appState = AppState()
    @State private var subscriptionService: SubscriptionService
    @State private var locationViewModel: LocationViewModel
    @State private var routineStore: RoutineStore
    @State private var routinesViewModel: RoutinesViewModel

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
                .onAppear { locationViewModel.loadInitialLocation() }
        }
    }
}
