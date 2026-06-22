import SwiftUI

@main
struct SunshiftApp: App {
    @State private var appState = AppState()
    @State private var subscriptionService = SubscriptionService()
    @State private var locationStore = LocationStore()

    var body: some Scene {
        WindowGroup {
            SunshiftRootView()
                .environment(appState)
                .environment(subscriptionService)
                .environment(locationStore)
        }
    }
}
