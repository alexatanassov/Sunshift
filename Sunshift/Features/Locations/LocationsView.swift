import SwiftUI

struct LocationsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.xl) {
                    // Hero
                    VStack(spacing: SunshiftSpacing.sm) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(SunshiftColors.sunsetAmber)
                        Text("Your Locations")
                            .font(SunshiftTypography.display())
                            .foregroundStyle(SunshiftColors.primaryText)
                        Text("Pin the places that matter — home, office, a favourite trail — and get accurate solar times for each one.")
                            .font(SunshiftTypography.body())
                            .foregroundStyle(SunshiftColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, SunshiftSpacing.lg)
                    .padding(.horizontal)

                    // Placeholder location rows
                    VStack(spacing: SunshiftSpacing.sm) {
                        PlaceholderLocationRow(
                            icon: "house.fill",
                            color: SunshiftColors.sunrisePeach,
                            name: "Home",
                            detail: "San Francisco, CA"
                        )
                        PlaceholderLocationRow(
                            icon: "briefcase.fill",
                            color: SunshiftColors.sunsetAmber,
                            name: "Office",
                            detail: "South of Market"
                        )
                        PlaceholderLocationRow(
                            icon: "mountain.2.fill",
                            color: SunshiftColors.duskPurple,
                            name: "Weekend Hike",
                            detail: "Marin Headlands"
                        )
                    }
                    .padding(.horizontal)

                    Label("Location pinning is coming in Stage 1", systemImage: "clock")
                        .font(SunshiftTypography.caption())
                        .foregroundStyle(SunshiftColors.secondaryText.opacity(0.6))

                    Spacer(minLength: SunshiftSpacing.xl)
                }
            }
            .background(SunshiftColors.softBackground)
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(SunshiftColors.softBackground)
    }
}

private struct PlaceholderLocationRow: View {
    let icon: String
    let color: Color
    let name: String
    let detail: String

    var body: some View {
        HStack(spacing: SunshiftSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(SunshiftColors.primaryText)
                Text(detail)
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
    LocationsView()
}
