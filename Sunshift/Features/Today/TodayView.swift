import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.xl) {
                    // Hero
                    VStack(spacing: SunshiftSpacing.sm) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(SunshiftColors.sunrisePeach)
                            .symbolEffect(.pulse)
                        Text("Your Solar Day")
                            .font(SunshiftTypography.display())
                            .foregroundStyle(SunshiftColors.primaryText)
                        Text("Sunrise, solar noon, and sunset. Updated for where you are.")
                            .font(SunshiftTypography.body())
                            .foregroundStyle(SunshiftColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, SunshiftSpacing.lg)
                    .padding(.horizontal)

                    // Placeholder event cards
                    VStack(spacing: SunshiftSpacing.sm) {
                        PlaceholderEventRow(
                            icon: "sunrise.fill",
                            color: SunshiftColors.sunrisePeach,
                            label: "Sunrise",
                            detail: "6:14 AM"
                        )
                        PlaceholderEventRow(
                            icon: "sun.max.fill",
                            color: SunshiftColors.sunsetAmber,
                            label: "Solar Noon",
                            detail: "1:02 PM"
                        )
                        PlaceholderEventRow(
                            icon: "sunset.fill",
                            color: SunshiftColors.sunsetAmber,
                            label: "Sunset",
                            detail: "8:11 PM"
                        )
                        PlaceholderEventRow(
                            icon: "moon.stars.fill",
                            color: SunshiftColors.duskPurple,
                            label: "Astronomical Twilight",
                            detail: "9:48 PM"
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: SunshiftSpacing.xl)
                }
            }
            .background(SunshiftColors.softBackground)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(SunshiftColors.softBackground)
    }
}

private struct PlaceholderEventRow: View {
    let icon: String
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: SunshiftSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            Text(label)
                .font(SunshiftTypography.headline())
                .foregroundStyle(SunshiftColors.primaryText)
            Spacer()
            Text(detail)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.secondaryText)
        }
        .padding(SunshiftSpacing.md)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

#Preview {
    TodayView()
}
