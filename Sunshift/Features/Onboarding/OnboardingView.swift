import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 96))
                .foregroundStyle(SunshiftColor.sunrise)
            VStack(spacing: 8) {
                Text("Sunshift")
                    .font(SunshiftFont.display(36))
                Text("Live in sync with the sun.")
                    .font(SunshiftFont.body())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Get Started") {
                appState.hasCompletedOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
