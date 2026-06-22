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
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            RoutinesView()
                .tabItem { Label("Routines", systemImage: "bell.fill") }
            LocationsView()
                .tabItem { Label("Locations", systemImage: "location.fill") }
            PlusView()
                .tabItem { Label("Plus", systemImage: "sparkles") }
        }
    }
}

#Preview {
    SunshiftRootView()
        .environment(AppState())
}
