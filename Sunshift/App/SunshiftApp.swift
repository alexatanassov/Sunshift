import SwiftUI

@main
struct SunshiftApp: App {
    @State private var appState = AppState()
    @State private var subscriptionService: SubscriptionService
    @State private var locationViewModel: LocationViewModel

    init() {
        let sub = SubscriptionService()
        _subscriptionService = State(wrappedValue: sub)
        _locationViewModel = State(wrappedValue: LocationViewModel(subscriptionService: sub))
    }

    var body: some Scene {
        WindowGroup {
            SunshiftRootView()
                .environment(appState)
                .environment(subscriptionService)
                .environment(locationViewModel)
                .onAppear { locationViewModel.loadInitialLocation() }
        }
    }
}
