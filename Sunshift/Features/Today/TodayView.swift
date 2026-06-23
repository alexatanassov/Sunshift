import SwiftUI

struct TodayView: View {
    @Environment(LocationViewModel.self) private var locationViewModel

    private var resolvedLocation: SavedLocation { locationViewModel.resolvedLocation }

    private var tz: TimeZone {
        TimeZone(identifier: resolvedLocation.timeZoneIdentifier) ?? .current
    }

    private var todaySchedule: SunSchedule? {
        let location = resolvedLocation
        let tzId = location.timeZoneIdentifier
        let tz = TimeZone(identifier: tzId) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let today = cal.startOfDay(for: Date())
        let input = SunCalculationInput(
            date: today,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneIdentifier: tzId
        )
        return try? SunService().sunSchedule(for: input)
    }

    private func timeString(for date: Date?) -> String {
        guard let date else { return "N/A" }
        return date.formattedTime(in: tz)
    }

    var body: some View {
        let schedule = todaySchedule
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
                        Text(resolvedLocation.name)
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
                            detail: timeString(for: schedule?.sunrise)
                        )
                        SolarEventRow(
                            icon: "sun.max.fill",
                            color: SunshiftColors.sunsetAmber,
                            label: "Solar Noon",
                            detail: timeString(for: schedule?.solarNoon)
                        )
                        SolarEventRow(
                            icon: "sunset.fill",
                            color: SunshiftColors.sunsetAmber,
                            label: "Sunset",
                            detail: timeString(for: schedule?.sunset)
                        )
                        SolarEventRow(
                            icon: "moon.stars.fill",
                            color: SunshiftColors.duskPurple,
                            label: "Last Light",
                            detail: timeString(for: schedule?.lastLight)
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
