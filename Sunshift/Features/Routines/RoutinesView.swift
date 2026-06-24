import SwiftUI

struct RoutinesView: View {
    @Environment(RoutinesViewModel.self) private var viewModel
    @State private var showingCreate = false
    @State private var editingRoutine: LightRoutine?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.sm) {
                    if viewModel.routines.isEmpty {
                        emptyState
                    } else {
                        routineList
                    }

                    if viewModel.isAtFreeLimit {
                        freeLimitHint
                            .padding(.top, SunshiftSpacing.xs)
                    }

                    Spacer(minLength: SunshiftSpacing.xl)
                }
                .padding(.horizontal, SunshiftSpacing.md)
                .padding(.top, SunshiftSpacing.xs)
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
                        viewModel.deleteRoutine(id: routine.id)
                        editingRoutine = nil
                    }
                )
            }
        }
        .background(SunshiftColors.softBackground)
    }

    // MARK: - Subviews

    private var routineList: some View {
        VStack(spacing: SunshiftSpacing.sm) {
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
            Image(systemName: "bell.slash")
                .font(.system(size: 44))
                .foregroundStyle(SunshiftColors.secondaryText.opacity(0.35))
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
        HStack(spacing: SunshiftSpacing.sm) {
            Image(systemName: "sparkles")
                .font(.body)
                .foregroundStyle(SunshiftColors.duskPurple)
            VStack(alignment: .leading, spacing: 2) {
                Text("Want more routines?")
                    .font(SunshiftTypography.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(SunshiftColors.primaryText)
                Text("Sunshift Plus lets you add as many as you like.")
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
                    Color.clear.frame(width: 44)
                }
                .padding(SunshiftSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            // Enable toggle, overlaid at trailing edge
            Button(action: onToggle) {
                Image(systemName: routine.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(
                        routine.isEnabled
                            ? SunshiftColors.sunsetAmber
                            : SunshiftColors.secondaryText.opacity(0.3)
                    )
                    .animation(.easeInOut(duration: 0.15), value: routine.isEnabled)
            }
            .buttonStyle(.plain)
            .padding(.trailing, SunshiftSpacing.md)
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
        .accessibilityHint("Double-tap to edit. Toggle circle to enable or disable.")
    }

    private var eventIcon: some View {
        Image(systemName: iconName(for: routine.sunEventType))
            .font(.title2)
            .foregroundStyle(iconColor(for: routine.sunEventType))
            .frame(width: 32)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 3) {
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
}
