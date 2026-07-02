import SwiftUI

struct TodayView: View {
    @Environment(LocationViewModel.self) private var locationViewModel
    @Environment(RoutineStore.self) private var routineStore
    @State private var viewModel = TodayViewModel()
    private let sunService = SunService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.xl) {
                    mainContent

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
        .onChange(of: routineStore.routines) { refresh() }
    }

    @ViewBuilder
    private var mainContent: some View {
        if locationViewModel.activeLocation == nil {
            TodayEmptyLocationView()
        } else if !viewModel.hasRefreshed {
            TodayLoadingView()
        } else if let error = viewModel.errorMessage {
            TodayErrorView(message: error, onRetry: refresh)
        } else {
            HeroCard(viewModel: viewModel)
            if let schedule = viewModel.schedule {
                TodayTimelineView(schedule: schedule, now: Date())
            }
            EventsSection(viewModel: viewModel)
            WeekPreviewView(viewModel: viewModel)
            NextRoutineCard(viewModel: viewModel)
        }
    }

    private func refresh() {
        let enabledRoutine = RoutineScheduler.soonestUpcomingRoutine(
            in: routineStore.routines,
            sunService: sunService,
            location: locationViewModel.resolvedLocation,
            after: Date()
        )?.routine
        viewModel.refresh(
            location: locationViewModel.resolvedLocation,
            isUsingFallback: locationViewModel.isUsingFallback,
            enabledRoutine: enabledRoutine
        )
    }
}

// MARK: - Empty Location State

private struct TodayEmptyLocationView: View {
    var body: some View {
        VStack(spacing: SunshiftSpacing.md) {
            Spacer(minLength: SunshiftSpacing.xxl)

            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 52))
                .foregroundStyle(SunshiftColors.sunsetAmber)

            VStack(spacing: SunshiftSpacing.xs) {
                Text("Your light schedule starts here")
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(SunshiftColors.primaryText)
                    .multilineTextAlignment(.center)

                Text("Add a city or use your current location in the Locations tab.")
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: SunshiftSpacing.xxl)
        }
        .padding(.horizontal, SunshiftSpacing.xl)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("No location set. Add a city or use your current location in the Locations tab.")
    }
}

// MARK: - Loading State

private struct TodayLoadingView: View {
    var body: some View {
        VStack {
            Spacer(minLength: SunshiftSpacing.xxl)
            ProgressView()
                .tint(SunshiftColors.sunsetAmber)
                .scaleEffect(1.2)
            Spacer(minLength: SunshiftSpacing.xxl)
        }
        .accessibilityLabel("Loading your light schedule")
    }
}

// MARK: - Hero Card

private struct HeroCard: View {
    let viewModel: TodayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: SunshiftSpacing.xs) {
                countdownText
                Text(hint)
                    .font(SunshiftTypography.body())
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer(minLength: SunshiftSpacing.lg)

            Rectangle()
                .fill(.white.opacity(0.25))
                .frame(height: 1)
                .padding(.bottom, SunshiftSpacing.sm)

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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(heroAccessibilityLabel)
    }

    @ViewBuilder
    private var countdownText: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.white)
        } else if viewModel.isPolarNight {
            Text("Night all day")
                .font(SunshiftTypography.display(28))
                .foregroundStyle(.white.opacity(0.75))
        } else if let title = viewModel.nextEventTitle,
                  let countdown = viewModel.nextEventCountdownText {
            Text("\(naturalTitle(for: title)) \(countdown)")
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

    private func naturalTitle(for eventTitle: String) -> String {
        switch eventTitle {
        case "First Light":       return "First light"
        case "Blue Hour Start":   return "Blue hour starts"
        case "Sunrise":           return "Sunrise"
        case "Golden Hour Start": return "Golden hour starts"
        case "Solar Noon":        return "Solar noon"
        case "Golden Hour End":   return "Golden hour ends"
        case "Sunset":            return "Sunset"
        case "Blue Hour End":     return "Blue hour ends"
        case "Last Light":        return "Last light"
        default:                  return eventTitle
        }
    }

    @ViewBuilder
    private var daylightLabel: some View {
        if viewModel.isPolarDay {
            Text("Daylight all day")
                .font(SunshiftTypography.headline())
                .foregroundStyle(.white)
        } else if viewModel.isPolarNight {
            Text("No daylight today")
                .font(SunshiftTypography.headline())
                .foregroundStyle(.white.opacity(0.65))
        } else if let daylight = viewModel.daylightRemainingText {
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
        if viewModel.isPolarNight { return SunshiftGradients.night }
        if viewModel.isPolarDay || viewModel.daylightRemainingText != nil { return SunshiftGradients.sunrise }
        return SunshiftGradients.dusk
    }

    private var hint: String {
        guard viewModel.schedule != nil else { return "Finding your light." }
        if viewModel.isPolarDay   { return "The sun is with you all day." }
        if viewModel.isPolarNight { return "A quiet day here without the sun." }
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

    private var heroAccessibilityLabel: String {
        var parts: [String] = []
        if viewModel.isPolarDay {
            parts.append("Daylight all day")
        } else if viewModel.isPolarNight {
            parts.append("Night all day")
        } else if let title = viewModel.nextEventTitle, let countdown = viewModel.nextEventCountdownText {
            parts.append("\(naturalTitle(for: title)) \(countdown)")
        } else if viewModel.schedule != nil {
            parts.append("All done for today")
        }
        if let daylight = viewModel.daylightRemainingText {
            parts.append("\(daylight) of daylight left")
        } else if !viewModel.isPolarDay && !viewModel.isPolarNight {
            parts.append("Sun has set")
        }
        parts.append("Location: \(viewModel.locationDisplayName)")
        return parts.joined(separator: ". ")
    }
}

// MARK: - Events Section

private struct EventsSection: View {
    let viewModel: TodayViewModel

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isPolarDay || viewModel.isPolarNight {
                polarRow
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
            } else {
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
        }
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }

    private var polarRow: some View {
        let isPolarNight = viewModel.isPolarNight
        return HStack(spacing: SunshiftSpacing.md) {
            Image(systemName: isPolarNight ? "moon.stars.fill" : "sun.max.fill")
                .font(.title3)
                .foregroundStyle(isPolarNight ? SunshiftColors.duskPurple : SunshiftColors.sunsetAmber)
                .frame(width: 24)
            Text(isPolarNight ? "No sunrise today" : "The sun doesn't set today")
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.primaryText)
            Spacer()
        }
        .padding(.horizontal, SunshiftSpacing.md)
        .padding(.vertical, 14)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(detail)")
    }
}

// MARK: - Next Routine Card

private struct NextRoutineCard: View {
    let viewModel: TodayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.sm) {
            Text("Upcoming")
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.secondaryText)
                .textCase(.uppercase)
                .kerning(0.5)

            if viewModel.hasNextRoutine {
                HStack(alignment: .top, spacing: SunshiftSpacing.md) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundStyle(SunshiftColors.duskPurple)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: SunshiftSpacing.xs) {
                        Text(viewModel.nextRoutineName)
                            .font(SunshiftTypography.headline())
                            .foregroundStyle(SunshiftColors.primaryText)
                        Text(viewModel.nextRoutineTimeText)
                            .font(SunshiftTypography.body())
                            .foregroundStyle(SunshiftColors.secondaryText)
                            .monospacedDigit()
                        if !viewModel.nextRoutineTriggerText.isEmpty {
                            Text(viewModel.nextRoutineTriggerText)
                                .font(SunshiftTypography.caption())
                                .foregroundStyle(SunshiftColors.secondaryText.opacity(0.7))
                        }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: SunshiftSpacing.md) {
                    Image(systemName: "bell.slash")
                        .font(.title2)
                        .foregroundStyle(SunshiftColors.secondaryText.opacity(0.5))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: SunshiftSpacing.xs) {
                        Text("No routines yet")
                            .font(SunshiftTypography.headline())
                            .foregroundStyle(SunshiftColors.primaryText.opacity(0.55))
                        Text("Head to the Routines tab to add one.")
                            .font(SunshiftTypography.body())
                            .foregroundStyle(SunshiftColors.secondaryText)
                    }
                }
            }
        }
        .padding(SunshiftSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Error State

private struct TodayErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: SunshiftSpacing.lg) {
            Spacer(minLength: SunshiftSpacing.xxl)
            Image(systemName: "sun.haze.fill")
                .font(.system(size: 44))
                .foregroundStyle(SunshiftColors.sunsetAmber.opacity(0.6))
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
        .environment(SubscriptionService())
        .environment(LocationViewModel(subscriptionService: SubscriptionService()))
        .environment(RoutineStore())
}
