import SwiftUI

struct TodayView: View {
    @Environment(LocationViewModel.self) private var locationViewModel
    @State private var viewModel = TodayViewModel()

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
                        Text(viewModel.locationDisplayName)
                            .font(SunshiftTypography.caption())
                            .foregroundStyle(SunshiftColors.secondaryText)
                    }
                    .padding(.top, SunshiftSpacing.lg)
                    .padding(.horizontal)

                    // Solar event cards
                    VStack(spacing: SunshiftSpacing.sm) {
                        SolarEventRow(
                            icon: "sunrise.fill",
                            color: SunshiftColors.sunrisePeach,
                            label: "Sunrise",
                            detail: viewModel.sunriseText
                        )
                        SolarEventRow(
                            icon: "sun.max.fill",
                            color: SunshiftColors.sunsetAmber,
                            label: "Solar Noon",
                            detail: viewModel.solarNoonText
                        )
                        SolarEventRow(
                            icon: "sunset.fill",
                            color: SunshiftColors.sunsetAmber,
                            label: "Sunset",
                            detail: viewModel.sunsetText
                        )
                        SolarEventRow(
                            icon: "moon.stars.fill",
                            color: SunshiftColors.duskPurple,
                            label: "Last Light",
                            detail: viewModel.lastLightText
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: SunshiftSpacing.xl)

                    #if DEBUG
                    NavigationLink(destination: SolarDebugView()) {
                        Text("Solar Debug")
                            .font(SunshiftTypography.caption())
                            .foregroundStyle(SunshiftColors.secondaryText.opacity(0.6))
                    }
                    .padding(.bottom, SunshiftSpacing.md)
                    #endif
                }
            }
            .background(SunshiftColors.softBackground)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(SunshiftColors.softBackground)
        .task { refresh() }
        .onChange(of: locationViewModel.resolvedLocation.id) { refresh() }
    }

    private func refresh() {
        viewModel.refresh(
            location: locationViewModel.resolvedLocation,
            isUsingFallback: locationViewModel.isUsingFallback
        )
    }
}

private struct SolarEventRow: View {
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
                .monospacedDigit()
        }
        .padding(SunshiftSpacing.md)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

#Preview {
    TodayView()
        .environment(LocationViewModel(subscriptionService: SubscriptionService()))
}
