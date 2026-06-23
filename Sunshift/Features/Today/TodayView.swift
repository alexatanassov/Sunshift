import SwiftUI

struct TodayView: View {
    @Environment(LocationViewModel.self) private var locationViewModel
    @State private var viewModel = TodayViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.xl) {
                    if let error = viewModel.errorMessage {
                        TodayErrorView(message: error, onRetry: refresh)
                    } else {
                        HeroCard(viewModel: viewModel)
                        EventsSection(viewModel: viewModel)
                    }

                    #if DEBUG
                    NavigationLink(destination: SolarDebugView()) {
                        Text("Solar Debug")
                            .font(SunshiftTypography.caption())
                            .foregroundStyle(SunshiftColors.secondaryText.opacity(0.6))
                    }
                    .padding(.bottom, SunshiftSpacing.sm)
                    #endif
                }
                .padding(.horizontal, SunshiftSpacing.md)
                .padding(.top, SunshiftSpacing.xs)
                .padding(.bottom, SunshiftSpacing.xl)
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

// MARK: - Hero Card

private struct HeroCard: View {
    let viewModel: TodayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Countdown + hint
            VStack(alignment: .leading, spacing: SunshiftSpacing.xs) {
                countdownText
                Text(hint)
                    .font(SunshiftTypography.body())
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer(minLength: SunshiftSpacing.lg)

            // Separator
            Rectangle()
                .fill(.white.opacity(0.25))
                .frame(height: 1)
                .padding(.bottom, SunshiftSpacing.sm)

            // Daylight remaining + location
            HStack(alignment: .center) {
                daylightLabel
                Spacer()
                locationRow
            }
        }
        .padding(SunshiftSpacing.lg)
        .frame(minHeight: 200)
        .background(heroGradient, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.large))
        .cardShadow()
    }

    @ViewBuilder
    private var countdownText: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.white)
        } else if let title = viewModel.nextEventTitle,
                  let countdown = viewModel.nextEventCountdownText {
            Text("\(title) \(countdown)")
                .font(SunshiftTypography.display(30))
                .foregroundStyle(.white)
        } else if viewModel.schedule != nil {
            Text("All done for today")
                .font(SunshiftTypography.display(28))
                .foregroundStyle(.white.opacity(0.75))
        } else {
            Text("Calculating...")
                .font(SunshiftTypography.display(28))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    @ViewBuilder
    private var daylightLabel: some View {
        if let daylight = viewModel.daylightRemainingText {
            Text("\(daylight) of daylight left")
                .font(SunshiftTypography.headline())
                .foregroundStyle(.white)
        } else {
            Text("Sun has set")
                .font(SunshiftTypography.headline())
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    @ViewBuilder
    private var locationRow: some View {
        HStack(spacing: SunshiftSpacing.xs) {
            Image(systemName: "mappin.circle.fill")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(viewModel.locationDisplayName)
                .font(SunshiftTypography.caption())
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
            if viewModel.locationKind == .fallback {
                Text("Sample")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(SunshiftColors.sunsetAmber)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.92), in: Capsule())
            }
        }
    }

    private var heroGradient: LinearGradient {
        viewModel.daylightRemainingText != nil ? SunshiftGradients.sunrise : SunshiftGradients.dusk
    }

    private var hint: String {
        guard viewModel.schedule != nil else { return "Finding your light." }
        switch viewModel.nextEventTitle {
        case "First Light":       return "The sky is beginning to brighten."
        case "Blue Hour Start":   return "A calm blue light this morning."
        case "Sunrise":           return "A beautiful start to the day."
        case "Golden Hour Start": return "Morning light at its best."
        case "Solar Noon":        return "The sun is at its peak."
        case "Golden Hour End":   return "Good time for an evening walk."
        case "Sunset":            return "The sky is about to put on a show."
        case "Blue Hour End":     return "A quiet moment before dark."
        case "Last Light":        return "Night is almost here."
        default:                  return "Rest well."
        }
    }
}

// MARK: - Events Section

private struct EventsSection: View {
    let viewModel: TodayViewModel

    var body: some View {
        VStack(spacing: 0) {
            EventRow(
                icon: "sunrise.fill",
                color: SunshiftColors.sunrisePeach,
                label: "Sunrise",
                detail: viewModel.sunriseText
            )
            rowDivider
            EventRow(
                icon: "sunset.fill",
                color: SunshiftColors.sunsetAmber,
                label: "Sunset",
                detail: viewModel.sunsetText
            )
            rowDivider
            EventRow(
                icon: "sun.max.fill",
                color: SunshiftColors.sunsetAmber,
                label: "Golden Hour",
                detail: viewModel.goldenHourText
            )
            rowDivider
            EventRow(
                icon: "moon.stars.fill",
                color: SunshiftColors.duskPurple,
                label: "Last Light",
                detail: viewModel.lastLightText
            )
        }
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 52)
    }
}

private struct EventRow: View {
    let icon: String
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: SunshiftSpacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.primaryText)
            Spacer()
            Text(detail)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.secondaryText)
                .monospacedDigit()
        }
        .padding(.horizontal, SunshiftSpacing.md)
        .padding(.vertical, 14)
    }
}

// MARK: - Error State

private struct TodayErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: SunshiftSpacing.lg) {
            Spacer(minLength: SunshiftSpacing.xxl)
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(SunshiftColors.secondaryText)
            Text(message)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.secondaryText)
                .multilineTextAlignment(.center)
            Button("Try Again", action: onRetry)
                .font(SunshiftTypography.headline())
                .foregroundStyle(SunshiftColors.sunsetAmber)
            Spacer(minLength: SunshiftSpacing.xxl)
        }
        .padding(.horizontal, SunshiftSpacing.xl)
    }
}

#Preview {
    TodayView()
        .environment(LocationViewModel(subscriptionService: SubscriptionService()))
}
