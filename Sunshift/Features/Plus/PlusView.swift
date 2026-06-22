import SwiftUI

struct PlusView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.xl) {
                    // Hero
                    VStack(spacing: SunshiftSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 72))
                            .foregroundStyle(SunshiftGradients.sunrise)
                        Text("Sunshift Plus")
                            .font(SunshiftTypography.display())
                            .foregroundStyle(SunshiftColors.primaryText)
                        Text("Unlock everything the sun has to offer.")
                            .font(SunshiftTypography.body())
                            .foregroundStyle(SunshiftColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, SunshiftSpacing.lg)
                    .padding(.horizontal)

                    // Feature teasers
                    VStack(spacing: SunshiftSpacing.sm) {
                        PlusFeatureRow(
                            icon: "bell.badge.fill",
                            color: SunshiftColors.sunrisePeach,
                            title: "Unlimited Routines",
                            detail: "Free tier includes 1 active routine"
                        )
                        PlusFeatureRow(
                            icon: "location.fill",
                            color: SunshiftColors.sunsetAmber,
                            title: "Saved Locations",
                            detail: "Pin home, office, or anywhere you spend time"
                        )
                        PlusFeatureRow(
                            icon: "calendar",
                            color: SunshiftColors.duskPurple,
                            title: "7-Day Light Preview",
                            detail: "See sunrise and sunset times for the week ahead"
                        )
                        PlusFeatureRow(
                            icon: "app.badge.fill",
                            color: SunshiftColors.nightNavy,
                            title: "Home Screen Widgets",
                            detail: "Your next sun event, glanceable on the home screen"
                        )
                    }
                    .padding(.horizontal)

                    // CTA
                    Button(action: {}) {
                        Text("Coming Soon")
                            .font(SunshiftTypography.headline())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(true)
                    .padding(.horizontal)

                    Spacer(minLength: SunshiftSpacing.xl)
                }
            }
            .background(SunshiftColors.softBackground)
            .navigationTitle("Plus")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(SunshiftColors.softBackground)
    }
}

private struct PlusFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: SunshiftSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(SunshiftColors.primaryText)
                Text(detail)
                    .font(SunshiftTypography.caption())
                    .foregroundStyle(SunshiftColors.secondaryText)
            }
            Spacer()
        }
        .padding(SunshiftSpacing.md)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

#Preview {
    PlusView()
}
