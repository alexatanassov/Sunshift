import SwiftUI

struct RoutinesView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.xl) {
                    // Hero
                    VStack(spacing: SunshiftSpacing.sm) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(SunshiftColors.duskPurple)
                        Text("Solar Routines")
                            .font(SunshiftTypography.display())
                            .foregroundStyle(SunshiftColors.primaryText)
                        Text("Create habits that fire at sunrise, sunset, or any solar milestone — every day, automatically.")
                            .font(SunshiftTypography.body())
                            .foregroundStyle(SunshiftColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, SunshiftSpacing.lg)
                    .padding(.horizontal)

                    // Placeholder routine rows
                    VStack(spacing: SunshiftSpacing.sm) {
                        PlaceholderRoutineRow(
                            icon: "sunrise.fill",
                            color: SunshiftColors.sunrisePeach,
                            title: "Morning Wind-Up",
                            trigger: "At Sunrise"
                        )
                        PlaceholderRoutineRow(
                            icon: "sun.max.fill",
                            color: SunshiftColors.sunsetAmber,
                            title: "Midday Check-In",
                            trigger: "At Solar Noon"
                        )
                        PlaceholderRoutineRow(
                            icon: "sunset.fill",
                            color: SunshiftColors.duskPurple,
                            title: "Evening Wind-Down",
                            trigger: "30 min before Sunset"
                        )
                    }
                    .padding(.horizontal)

                    Label("Routines are coming in Stage 1", systemImage: "clock")
                        .font(SunshiftTypography.caption())
                        .foregroundStyle(SunshiftColors.secondaryText.opacity(0.6))

                    Spacer(minLength: SunshiftSpacing.xl)
                }
            }
            .background(SunshiftColors.softBackground)
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(SunshiftColors.softBackground)
    }
}

private struct PlaceholderRoutineRow: View {
    let icon: String
    let color: Color
    let title: String
    let trigger: String

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
                Text(trigger)
                    .font(SunshiftTypography.caption())
                    .foregroundStyle(SunshiftColors.secondaryText)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(SunshiftColors.secondaryText.opacity(0.5))
        }
        .padding(SunshiftSpacing.md)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

#Preview {
    RoutinesView()
}
