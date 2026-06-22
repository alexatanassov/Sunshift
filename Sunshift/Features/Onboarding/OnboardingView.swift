import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            SunshiftColors.softBackground.ignoresSafeArea()
            VStack(spacing: SunshiftSpacing.xl) {
                Spacer()
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(SunshiftGradients.sunrise)
                VStack(spacing: SunshiftSpacing.sm) {
                    Text("Sunshift")
                        .font(SunshiftTypography.display(36))
                        .foregroundStyle(SunshiftColors.primaryText)
                    Text("Live in sync with the sun.")
                        .font(SunshiftTypography.body())
                        .foregroundStyle(SunshiftColors.secondaryText)
                }
                Spacer()
                Button("Get Started") {
                    appState.hasCompletedOnboarding = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(SunshiftSpacing.xl)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
