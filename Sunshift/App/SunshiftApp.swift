import SwiftUI

@main
struct SunshiftApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            SunshiftRootView()
                .environment(appState)
        }
    }
}
