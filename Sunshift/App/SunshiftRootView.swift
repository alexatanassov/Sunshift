import SwiftUI

struct SunshiftRootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            RoutinesView()
                .tabItem { Label("Routines", systemImage: "list.bullet.rectangle") }
            LocationsView()
                .tabItem { Label("Locations", systemImage: "map") }
        }
    }
}

#Preview {
    SunshiftRootView()
        .environment(AppState())
}
