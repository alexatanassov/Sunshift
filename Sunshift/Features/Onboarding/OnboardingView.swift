import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(RoutinesViewModel.self) private var routinesViewModel
    @Environment(SubscriptionService.self) private var subscriptionService

    @State private var viewModel = OnboardingViewModel()
    @State private var slideFromTrailing = true

    var body: some View {
        ZStack {
            SunshiftColors.softBackground.ignoresSafeArea()

            currentStep
                .id(viewModel.step)
                .transition(.asymmetric(
                    insertion: .move(edge: slideFromTrailing ? .trailing : .leading)
                        .combined(with: .opacity),
                    removal: .move(edge: slideFromTrailing ? .leading : .trailing)
                        .combined(with: .opacity)
                ))
        }
    }

    @ViewBuilder
    private var currentStep: some View {
        switch viewModel.step {
        case .welcome:
            WelcomeStep(onContinue: goForward)
        case .templatePick:
            TemplatePickStep(
                viewModel: viewModel,
                isPlusUser: subscriptionService.isPlusUser,
                onBack: goBack,
                onContinue: goForward
            )
        case .customize:
            CustomizeStep(viewModel: viewModel, onBack: goBack, onContinue: goForward)
        case .confirm:
            ConfirmStep(viewModel: viewModel, onBack: goBack, onDone: complete)
        }
    }

    private func goForward() {
        slideFromTrailing = true
        withAnimation(.easeInOut(duration: 0.35)) {
            viewModel.advance()
        }
    }

    private func goBack() {
        slideFromTrailing = false
        withAnimation(.easeInOut(duration: 0.35)) {
            viewModel.goBack()
        }
    }

    private func complete() {
        routinesViewModel.upsertOnboardingRoutine(viewModel.buildRoutine())
        withAnimation(.easeInOut(duration: 0.4)) {
            appState.hasCompletedOnboarding = true
        }
    }
}

// MARK: - Welcome

private struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: SunshiftSpacing.xl) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(SunshiftGradients.dusk)

                VStack(spacing: SunshiftSpacing.sm) {
                    Text("Sunshift")
                        .font(SunshiftTypography.display(36))
                        .foregroundStyle(SunshiftColors.primaryText)

                    Text("Routines that move with the sun, not the clock.")
                        .font(SunshiftTypography.body())
                        .foregroundStyle(SunshiftColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, SunshiftSpacing.xl)

            Spacer()

            Button("Get Started", action: onContinue)
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .padding(.horizontal, SunshiftSpacing.xl)
                .padding(.bottom, SunshiftSpacing.xxl)
        }
    }
}

// MARK: - Template Pick

private struct TemplatePickStep: View {
    let viewModel: OnboardingViewModel
    let isPlusUser: Bool
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingNavBar(onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: SunshiftSpacing.lg) {
                    OnboardingHeadline(
                        title: "Choose your first routine",
                        subtitle: "You can always change this later."
                    )

                    VStack(spacing: SunshiftSpacing.sm) {
                        ForEach(RoutineTemplate.allCases) { template in
                            TemplateCard(
                                template: template,
                                isSelected: viewModel.selectedTemplate == template,
                                isPlusUser: isPlusUser
                            ) {
                                viewModel.selectTemplate(template, isPlusUser: isPlusUser)
                            }
                        }
                    }

                    if let locked = viewModel.lockedTemplateHint {
                        LockedTemplateBanner(templateName: locked.displayName) {
                            viewModel.dismissLockedHint()
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, SunshiftSpacing.lg)
                .padding(.bottom, SunshiftSpacing.xl)
                .animation(.easeInOut(duration: 0.2), value: viewModel.lockedTemplateHint)
            }

            Button("Continue", action: onContinue)
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .padding(.horizontal, SunshiftSpacing.xl)
                .padding(.bottom, SunshiftSpacing.xxl)
        }
    }
}

// MARK: - Customize

private struct CustomizeStep: View {
    @Bindable var viewModel: OnboardingViewModel
    let onBack: () -> Void
    let onContinue: () -> Void

    private let offsetPresets: [(label: String, minutes: Int)] = [
        ("At", 0), ("15 min", 15), ("30 min", 30), ("1 hr", 60)
    ]

    var body: some View {
        VStack(spacing: 0) {
            OnboardingNavBar(onBack: onBack)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: SunshiftSpacing.xl) {
                    OnboardingHeadline(
                        title: "Customize your timing",
                        subtitle: "Timed around \(viewModel.selectedTemplate.defaultSunEventType.displayName)"
                    )

                    VStack(alignment: .leading, spacing: SunshiftSpacing.sm) {
                        sectionLabel("When")
                        OffsetPillRow(selectedMinutes: $viewModel.offsetMinutes, presets: offsetPresets)

                        if viewModel.offsetMinutes > 0 {
                            Picker("Direction", selection: $viewModel.isBeforeEvent) {
                                Text("Before").tag(true)
                                Text("After").tag(false)
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    VStack(alignment: .leading, spacing: SunshiftSpacing.sm) {
                        sectionLabel("Which days")
                        WeekdayChipRow(selection: $viewModel.selectedWeekdays)
                            .padding(.vertical, SunshiftSpacing.xs)
                        Text(viewModel.selectedWeekdays.friendlyLabel)
                            .font(SunshiftTypography.caption())
                            .foregroundStyle(SunshiftColors.secondaryText)
                    }
                }
                .padding(.horizontal, SunshiftSpacing.lg)
                .padding(.bottom, SunshiftSpacing.xl)
            }

            Button("Continue", action: onContinue)
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .padding(.horizontal, SunshiftSpacing.xl)
                .padding(.bottom, SunshiftSpacing.xxl)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(SunshiftTypography.caption())
            .foregroundStyle(SunshiftColors.secondaryText)
            .textCase(.uppercase)
            .kerning(0.5)
    }
}

// MARK: - Confirm

private struct ConfirmStep: View {
    let viewModel: OnboardingViewModel
    let onBack: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingNavBar(onBack: onBack)

            Spacer()

            VStack(spacing: SunshiftSpacing.xl) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(SunshiftColors.sunsetAmber)

                VStack(spacing: SunshiftSpacing.sm) {
                    Text("You're set.")
                        .font(SunshiftTypography.display(30))
                        .foregroundStyle(SunshiftColors.primaryText)

                    Text(summaryText)
                        .font(SunshiftTypography.body())
                        .foregroundStyle(SunshiftColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, SunshiftSpacing.xl)

            Spacer()

            Button("Start exploring", action: onDone)
                .buttonStyle(OnboardingPrimaryButtonStyle())
                .padding(.horizontal, SunshiftSpacing.xl)
                .padding(.bottom, SunshiftSpacing.xxl)
        }
    }

    private var summaryText: String {
        let name = viewModel.selectedTemplate.displayName
        let event = viewModel.selectedTemplate.defaultSunEventType.displayName
        let days = viewModel.selectedWeekdays.friendlyLabel.lowercased()
        let offset = viewModel.offsetMinutes
        if offset == 0 {
            return "\(name) at \(event), \(days)."
        }
        let dir = viewModel.isBeforeEvent ? "before" : "after"
        let offsetLabel: String
        if offset < 60 {
            offsetLabel = "\(offset) min"
        } else if offset == 60 {
            offsetLabel = "1 hr"
        } else {
            offsetLabel = "\(offset / 60) hr \(offset % 60) min"
        }
        return "\(name), \(offsetLabel) \(dir) \(event), \(days)."
    }
}

// MARK: - Shared subviews

private struct OnboardingNavBar: View {
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SunshiftColors.primaryText)
                    .frame(width: 44, height: 44)
            }
            Spacer()
        }
        .padding(.horizontal, SunshiftSpacing.md)
    }
}

private struct OnboardingHeadline: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.xs) {
            Text(title)
                .font(SunshiftTypography.display(26))
                .foregroundStyle(SunshiftColors.primaryText)
            Text(subtitle)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.secondaryText)
        }
    }
}

private struct TemplateCard: View {
    let template: RoutineTemplate
    let isSelected: Bool
    let isPlusUser: Bool
    let onTap: () -> Void

    private var isLocked: Bool { template.requiresPlus && !isPlusUser }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: SunshiftSpacing.md) {
                iconBadge
                labels
                Spacer()
                trailingMark
            }
            .padding(SunshiftSpacing.md)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium)
                    .stroke(isSelected ? SunshiftColors.sunsetAmber.opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
            .cardShadow()
            .opacity(isLocked ? 0.72 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var iconBadge: some View {
        let color = isLocked ? SunshiftColors.secondaryText.opacity(0.4) : eventColor
        return Image(systemName: eventIconName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(isLocked ? 0.07 : 0.12), in: Circle())
    }

    private var labels: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: SunshiftSpacing.xs) {
                Text(template.displayName)
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(isLocked ? SunshiftColors.secondaryText : SunshiftColors.primaryText)
                tierBadge
            }
            Text(previewText)
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.secondaryText.opacity(isLocked ? 0.55 : 0.85))
        }
    }

    @ViewBuilder
    private var tierBadge: some View {
        if template == .sunsetWalk {
            Text("Free")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(SunshiftColors.sunsetAmber)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(SunshiftColors.sunsetAmber.opacity(0.12), in: Capsule())
        } else if template.requiresPlus {
            Text("Plus")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(SunshiftColors.duskPurple)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(SunshiftColors.duskPurple.opacity(0.12), in: Capsule())
        }
    }

    @ViewBuilder
    private var trailingMark: some View {
        if isLocked {
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(SunshiftColors.secondaryText.opacity(0.35))
        } else if isSelected {
            Image(systemName: "checkmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(SunshiftColors.sunsetAmber)
        }
    }

    private var cardBackground: Color {
        isSelected ? SunshiftColors.sunsetAmber.opacity(0.06) : SunshiftColors.cardBackground
    }

    private var previewText: String {
        let event = template.defaultSunEventType.displayName
        let offset = template.defaultOffsetMinutes
        if offset == 0 { return "At \(event)" }
        let dir = template.defaultIsBeforeEvent ? "before" : "after"
        let label = offset < 60 ? "\(offset) min" : (offset == 60 ? "1 hr" : "\(offset / 60) hr \(offset % 60) min")
        return "\(label) \(dir) \(event)"
    }

    private var eventIconName: String {
        switch template.defaultSunEventType {
        case .sunrise, .firstLight, .civilTwilightStart: return "sunrise.fill"
        case .sunset, .lastLight, .civilTwilightEnd:     return "sunset.fill"
        case .goldenHourStart, .goldenHourEnd:           return "sun.haze.fill"
        case .blueHourStart, .blueHourEnd:               return "moon.haze.fill"
        case .solarNoon:                                 return "sun.max.fill"
        case .daylightRemaining:                         return "clock.fill"
        }
    }

    private var eventColor: Color {
        switch template.defaultSunEventType {
        case .sunrise, .firstLight, .civilTwilightStart: return SunshiftColors.sunrisePeach
        case .sunset, .lastLight, .civilTwilightEnd:     return SunshiftColors.sunsetAmber
        case .goldenHourStart, .goldenHourEnd:           return SunshiftColors.sunsetAmber
        case .blueHourStart, .blueHourEnd:               return SunshiftColors.duskPurple
        case .solarNoon:                                 return SunshiftColors.sunsetAmber
        case .daylightRemaining:                         return SunshiftColors.secondaryText
        }
    }
}

private struct LockedTemplateBanner: View {
    let templateName: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: SunshiftSpacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(SunshiftColors.duskPurple)
            Text("\(templateName) is part of Sunshift Plus.")
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.primaryText)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SunshiftColors.secondaryText)
            }
        }
        .padding(SunshiftSpacing.md)
        .background(
            SunshiftColors.duskPurple.opacity(0.08),
            in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium)
        )
    }
}

private struct OffsetPillRow: View {
    @Binding var selectedMinutes: Int
    let presets: [(label: String, minutes: Int)]

    var body: some View {
        HStack(spacing: SunshiftSpacing.sm) {
            ForEach(presets, id: \.minutes) { preset in
                let isSelected = selectedMinutes == preset.minutes
                Button {
                    selectedMinutes = preset.minutes
                } label: {
                    Text(preset.label)
                        .font(SunshiftTypography.caption())
                        .fontWeight(.semibold)
                        .padding(.horizontal, SunshiftSpacing.md)
                        .padding(.vertical, SunshiftSpacing.sm)
                        .foregroundStyle(isSelected ? Color.white : SunshiftColors.secondaryText)
                        .background(
                            isSelected
                                ? AnyShapeStyle(SunshiftColors.sunsetAmber)
                                : AnyShapeStyle(SunshiftColors.softBackground),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(SunshiftColors.secondaryText.opacity(isSelected ? 0 : 0.18), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            Spacer()
        }
    }
}

// MARK: - Button style

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SunshiftTypography.headline())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SunshiftSpacing.md)
            .background(
                SunshiftColors.sunsetAmber.opacity(configuration.isPressed ? 0.8 : 1.0),
                in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.large)
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Welcome") {
    OnboardingView()
        .environment(AppState())
        .environment(RoutinesViewModel(store: RoutineStore(), subscriptionService: SubscriptionService()))
        .environment(SubscriptionService())
}

#Preview("Template Pick") {
    TemplatePickStep(viewModel: OnboardingViewModel(), isPlusUser: false, onBack: {}, onContinue: {})
}

#Preview("Customize") {
    CustomizeStep(viewModel: OnboardingViewModel(), onBack: {}, onContinue: {})
}

#Preview("Confirm") {
    ConfirmStep(viewModel: OnboardingViewModel(), onBack: {}, onDone: {})
}
