import SwiftUI

struct RoutinesView: View {
    @Environment(RoutinesViewModel.self) private var viewModel
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(AlarmKitBridge.self) private var alarmKitBridge
    @Environment(NotificationPermissionService.self) private var notificationPermissionService
    @Environment(LocationViewModel.self) private var locationViewModel
    @State private var showingCreate = false
    @State private var editingRoutine: LightRoutine?
    @State private var showingPlus = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.sm) {
                    upcomingRoutineCard
                        .padding(.bottom, SunshiftSpacing.xs)

                    NotificationsNudgeCard(
                        notificationPermissionService: notificationPermissionService,
                        alarmKitBridge: alarmKitBridge
                    )
                    .padding(.bottom, SunshiftSpacing.xs)

                    if viewModel.routines.isEmpty {
                        emptyState
                    } else {
                        routineList
                    }

                    if viewModel.isAtFreeLimit {
                        freeLimitHint
                            .padding(.top, SunshiftSpacing.xs)
                    }
                }
                .padding(.horizontal, SunshiftSpacing.md)
                .padding(.top, SunshiftSpacing.sm)
                .padding(.bottom, SunshiftSpacing.xl)
            }
            .background(SunshiftColors.softBackground)
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewModel.canAddRoutine {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingCreate = true
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                        .tint(SunshiftColors.sunsetAmber)
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                RoutineEditView(
                    mode: .create,
                    onSave: { routine in
                        viewModel.addRoutine(routine)
                        showingCreate = false
                    },
                    onCancel: { showingCreate = false }
                )
            }
            .sheet(item: $editingRoutine) { routine in
                RoutineEditView(
                    mode: .edit(routine),
                    onSave: { updated in
                        viewModel.updateRoutine(updated)
                        editingRoutine = nil
                    },
                    onCancel: { editingRoutine = nil },
                    onDelete: {
                        alarmKitBridge.cancel(routineID: routine.id)
                        viewModel.deleteRoutine(id: routine.id)
                        editingRoutine = nil
                    }
                )
            }
            .sheet(isPresented: $showingPlus) {
                PlusView()
                    .environment(subscriptionService)
            }
        }
        .background(SunshiftColors.softBackground)
    }

    // MARK: - Subviews

    private var upcomingRoutineCard: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.xs) {
            if let upcoming = viewModel.upcomingRoutinePreview(location: locationViewModel.resolvedLocation) {
                Text("Time until \(upcoming.routineTitle)")
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(SunshiftColors.secondaryText)
                Text(upcoming.countdownText)
                    .font(SunshiftTypography.display(40))
                    .foregroundStyle(SunshiftColors.primaryText)
                    .monospacedDigit()
                Text(upcoming.summary)
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.secondaryText)
            } else {
                Text("No upcoming routine")
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(SunshiftColors.primaryText)
                Text("Create a routine that follows the sun.")
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.secondaryText)
            }
        }
        .padding(SunshiftSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.large))
        .cardShadow()
        .accessibilityElement(children: .combine)
    }

    private var routineList: some View {
        VStack(spacing: SunshiftSpacing.md) {
            ForEach(viewModel.routines) { routine in
                RoutineRow(
                    routine: routine,
                    trigger: viewModel.triggerDescription(for: routine),
                    days: viewModel.activeDaysSummary(for: routine),
                    onToggle: { viewModel.toggleEnabled(for: routine.id) },
                    onTap: { editingRoutine = routine }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: SunshiftSpacing.md) {
            Spacer(minLength: SunshiftSpacing.xxl)
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 48))
                .foregroundStyle(SunshiftColors.sunsetAmber.opacity(0.45))
            VStack(spacing: SunshiftSpacing.xs) {
                Text("No routines yet")
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(SunshiftColors.primaryText)
                Text("Add a routine to get notified around sunrise, sunset, or any solar event.")
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: SunshiftSpacing.xxl)
        }
        .padding(.horizontal, SunshiftSpacing.lg)
    }

    private var freeLimitHint: some View {
        Button {
            showingPlus = true
        } label: {
            HStack(spacing: SunshiftSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.body)
                    .foregroundStyle(SunshiftColors.duskPurple)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Want unlimited routines?")
                        .font(SunshiftTypography.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(SunshiftColors.primaryText)
                    Text("Helio Plus removes the limit.")
                        .font(SunshiftTypography.caption())
                        .foregroundStyle(SunshiftColors.secondaryText)
                }
                Spacer()
            }
            .padding(SunshiftSpacing.md)
            .background(
                SunshiftColors.duskPurple.opacity(0.08),
                in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notifications Nudge

private struct NotificationsNudgeCard: View {
    let notificationPermissionService: NotificationPermissionService
    let alarmKitBridge: AlarmKitBridge

    @State private var isRequesting = false

    private var nudgeState: NotificationNudgeState {
        NotificationNudgeState(
            notificationStatus: notificationPermissionService.authorizationStatus,
            isAlarmKitAuthorized: alarmKitBridge.isAlarmKitAuthorized
        )
    }

    var body: some View {
        if nudgeState != .hidden {
            VStack(alignment: .leading, spacing: SunshiftSpacing.sm) {
                HStack(spacing: SunshiftSpacing.sm) {
                    Image(systemName: "bell.badge.fill")
                        .font(.body)
                        .foregroundStyle(SunshiftColors.duskPurple)
                    Text("Turn on alerts")
                        .font(SunshiftTypography.headline())
                        .foregroundStyle(SunshiftColors.primaryText)
                    Spacer()
                }

                Text("Get notified when your next sun-based routine is ready.")
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.secondaryText)

                if nudgeState == .deniedInSettings {
                    Text("Alerts are turned off. Enable them in Settings to get notified.")
                        .font(SunshiftTypography.caption())
                        .foregroundStyle(SunshiftColors.secondaryText.opacity(0.75))
                } else {
                    Button(isRequesting ? "Requesting..." : "Enable Alerts") {
                        isRequesting = true
                        Task {
                            await notificationPermissionService.requestPermission()
                            await alarmKitBridge.requestAlarmPermission()
                            isRequesting = false
                        }
                    }
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(SunshiftColors.sunsetAmber)
                    .disabled(isRequesting)
                }
            }
            .padding(SunshiftSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                SunshiftColors.duskPurple.opacity(0.08),
                in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium)
            )
            .transition(.opacity)
        }
    }
}

// MARK: - Routine Row

private struct RoutineRow: View {
    let routine: LightRoutine
    let trigger: String
    let days: String
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            // Tappable main area
            Button(action: onTap) {
                HStack(spacing: SunshiftSpacing.md) {
                    eventIcon
                    content
                    Spacer()
                    Color.clear.frame(width: 52)
                }
                .padding(SunshiftSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            // Enable toggle, overlaid at trailing edge
            Button(action: onToggle) {
                Image(systemName: routine.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        routine.isEnabled
                            ? SunshiftColors.sunsetAmber
                            : SunshiftColors.secondaryText.opacity(0.4)
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .animation(.easeInOut(duration: 0.15), value: routine.isEnabled)
            }
            .buttonStyle(.plain)
            .padding(.trailing, SunshiftSpacing.sm)
        }
        .background(
            SunshiftColors.cardBackground,
            in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium)
        )
        .cardShadow()
        .opacity(routine.isEnabled ? 1 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: routine.isEnabled)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(routine.title). \(trigger). \(days). \(routine.isEnabled ? "Enabled" : "Disabled")")
        .accessibilityHint("Double-tap to edit. Toggle to enable or disable.")
    }

    private var eventIcon: some View {
        let color = iconColor(for: routine.sunEventType)
        return Image(systemName: iconName(for: routine.sunEventType))
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.12), in: Circle())
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.xs) {
            Text(routine.title)
                .font(SunshiftTypography.headline())
                .foregroundStyle(SunshiftColors.primaryText)
                .lineLimit(1)
            Text(trigger)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.secondaryText)
                .lineLimit(1)
            Text(days)
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.secondaryText.opacity(0.7))
                .lineLimit(1)
        }
    }

    private func iconName(for eventType: SunEventType) -> String {
        switch eventType {
        case .sunrise, .firstLight, .civilTwilightStart:   return "sunrise.fill"
        case .sunset, .lastLight, .civilTwilightEnd:       return "sunset.fill"
        case .goldenHourStart, .goldenHourEnd:             return "sun.haze.fill"
        case .blueHourStart, .blueHourEnd:                 return "moon.haze.fill"
        case .solarNoon:                                   return "sun.max.fill"
        case .daylightRemaining:                           return "clock.fill"
        }
    }

    private func iconColor(for eventType: SunEventType) -> Color {
        switch eventType {
        case .sunrise, .firstLight, .civilTwilightStart:   return SunshiftColors.sunrisePeach
        case .sunset, .lastLight, .civilTwilightEnd:       return SunshiftColors.sunsetAmber
        case .goldenHourStart, .goldenHourEnd:             return SunshiftColors.sunsetAmber
        case .blueHourStart, .blueHourEnd:                 return SunshiftColors.duskPurple
        case .solarNoon:                                   return SunshiftColors.sunsetAmber
        case .daylightRemaining:                           return SunshiftColors.secondaryText
        }
    }
}

#Preview {
    let store = RoutineStore()
    let sub = SubscriptionService()
    let vm = RoutinesViewModel(store: store, subscriptionService: sub)
    RoutinesView()
        .environment(vm)
        .environment(sub)
        .environment(LocationViewModel(subscriptionService: sub))
        .environment(AlarmKitBridge())
        .environment(NotificationPermissionService())
}
