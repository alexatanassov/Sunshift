import SwiftUI

@main
struct SunshiftApp: App {
    @State private var appState = AppState()
    @State private var subscriptionService = SubscriptionService()

    var body: some Scene {
        WindowGroup {
            SunshiftRootView()
                .environment(appState)
                .environment(subscriptionService)
        }
    }
}
