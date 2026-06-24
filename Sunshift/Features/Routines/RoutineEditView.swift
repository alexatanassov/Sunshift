import SwiftUI

struct RoutineEditView: View {
    enum Mode {
        case create
        case edit(LightRoutine)
    }

    private let mode: Mode
    private let onSave: (LightRoutine) -> Void
    private let onCancel: () -> Void
    private let onDelete: (() -> Void)?

    @Environment(SubscriptionService.self) private var subscriptionService

    @State private var title: String
    @State private var selectedTemplate: RoutineTemplate?
    @State private var sunEventType: SunEventType
    @State private var offsetMinutes: Int
    @State private var isBeforeEvent: Bool
    @State private var selectedWeekdays: WeekdaySelection
    @State private var isEnabled: Bool
    @State private var notificationMessage: String

    private var isCreating: Bool {
        if case .create = mode { return true }
        return false
    }

    private var existingRoutine: LightRoutine? {
        if case .edit(let r) = mode { return r }
        return nil
    }

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(
        mode: Mode,
        onSave: @escaping (LightRoutine) -> Void,
        onCancel: @escaping () -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete

        switch mode {
        case .create:
            let template = RoutineTemplate.sunsetWalk
            _title = State(initialValue: template.displayName)
            _selectedTemplate = State(initialValue: template)
            _sunEventType = State(initialValue: template.defaultSunEventType)
            _offsetMinutes = State(initialValue: template.defaultOffsetMinutes)
            _isBeforeEvent = State(initialValue: template.defaultIsBeforeEvent)
            _selectedWeekdays = State(initialValue: .everyday)
            _isEnabled = State(initialValue: true)
            _notificationMessage = State(initialValue: template.defaultNotificationMessage)

        case .edit(let routine):
            _title = State(initialValue: routine.title)
            _selectedTemplate = State(initialValue: routine.templateType)
            _sunEventType = State(initialValue: routine.sunEventType)
            _offsetMinutes = State(initialValue: routine.offsetMinutes)
            _isBeforeEvent = State(initialValue: routine.isBeforeEvent)
            _selectedWeekdays = State(initialValue: routine.selectedWeekdays)
            _isEnabled = State(initialValue: routine.isEnabled)
            _notificationMessage = State(initialValue: routine.notificationMessage)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                if isCreating { templateSection }
                timingSection
                scheduleSection
                notificationSection
                statusSection
                if !isCreating { deleteSection }
            }
            .scrollContentBackground(.hidden)
            .background(SunshiftColors.softBackground)
            .navigationTitle(isCreating ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(isSaveDisabled)
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Name") {
            TextField("Routine name", text: $title)
                .font(SunshiftTypography.body())
        }
    }

    private var templateSection: some View {
        Section {
            ForEach(RoutineTemplate.allCases) { template in
                Button {
                    applyTemplate(template)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: SunshiftSpacing.xs) {
                                Text(template.displayName)
                                    .font(SunshiftTypography.body())
                                    .foregroundStyle(SunshiftColors.primaryText)
                                if template.requiresPlus {
                                    Text("Plus")
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SunshiftColors.duskPurple)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(SunshiftColors.duskPurple.opacity(0.12), in: Capsule())
                                }
                            }
                            Text(templatePreviewText(template))
                                .font(SunshiftTypography.caption())
                                .foregroundStyle(SunshiftColors.secondaryText)
                        }
                        Spacer()
                        if selectedTemplate == template {
                            Image(systemName: "checkmark")
                                .foregroundStyle(SunshiftColors.sunsetAmber)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        } header: {
            Text("Template")
        } footer: {
            Text("Templates fill in the timing for you. Adjust anything below.")
        }
    }

    private var timingSection: some View {
        Section("Timing") {
            Picker("Event", selection: $sunEventType) {
                ForEach(SunEventType.routineTriggerCases) { event in
                    Text(event.displayName).tag(event)
                }
            }

            Picker("Offset", selection: $offsetMinutes) {
                ForEach(ReminderOffset.presets, id: \.offsetMinutes) { offset in
                    Text(offsetPickerLabel(offset)).tag(offset.offsetMinutes)
                }
            }

            if offsetMinutes > 0 {
                Picker("Direction", selection: $isBeforeEvent) {
                    Text("Before").tag(true)
                    Text("After").tag(false)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var scheduleSection: some View {
        Section {
            WeekdayChipRow(selection: $selectedWeekdays)
                .padding(.vertical, SunshiftSpacing.xs)
        } header: {
            Text("Days")
        } footer: {
            Text(selectedWeekdays.friendlyLabel)
                .foregroundStyle(SunshiftColors.secondaryText)
        }
    }

    private var notificationSection: some View {
        Section {
            TextField("Notification message", text: $notificationMessage, axis: .vertical)
                .font(SunshiftTypography.body())
                .lineLimit(3, reservesSpace: false)
        } header: {
            Text("Message")
        } footer: {
            if !subscriptionService.canUseCustomNotificationMessages {
                Text("Custom messages are available with Sunshift Plus.")
                    .foregroundStyle(SunshiftColors.duskPurple.opacity(0.8))
            }
        }
    }

    private var statusSection: some View {
        Section {
            Toggle("Enabled", isOn: $isEnabled)
                .tint(SunshiftColors.sunsetAmber)
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                HStack {
                    Spacer()
                    Text("Delete Routine")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Actions

    private func applyTemplate(_ template: RoutineTemplate) {
        selectedTemplate = template
        sunEventType = template.defaultSunEventType
        offsetMinutes = template.defaultOffsetMinutes
        isBeforeEvent = template.defaultIsBeforeEvent
        notificationMessage = template.defaultNotificationMessage
        if title.isEmpty || RoutineTemplate.allCases.map(\.displayName).contains(title) {
            title = template.displayName
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        switch mode {
        case .create:
            let routine = LightRoutine(
                title: trimmed,
                templateType: selectedTemplate,
                sunEventType: sunEventType,
                offsetMinutes: offsetMinutes,
                isBeforeEvent: isBeforeEvent,
                selectedWeekdays: selectedWeekdays,
                isEnabled: isEnabled,
                notificationMessage: notificationMessage
            )
            onSave(routine)

        case .edit(let existing):
            var updated = existing
            updated.title = trimmed
            updated.templateType = selectedTemplate
            updated.sunEventType = sunEventType
            updated.offsetMinutes = offsetMinutes
            updated.isBeforeEvent = isBeforeEvent
            updated.selectedWeekdays = selectedWeekdays
            updated.isEnabled = isEnabled
            updated.notificationMessage = notificationMessage
            onSave(updated)
        }
    }

    // MARK: - Helpers

    private func offsetPickerLabel(_ offset: ReminderOffset) -> String {
        switch offset {
        case .atEvent: return "At event"
        case .preset(let m), .custom(let m):
            if m < 60 { return "\(m) min" }
            let h = m / 60, r = m % 60
            if r == 0 { return h == 1 ? "1 hr" : "\(h) hrs" }
            return "\(h) hr \(r) min"
        }
    }

    private func templatePreviewText(_ template: RoutineTemplate) -> String {
        let event = template.defaultSunEventType.displayName
        if template.defaultOffsetMinutes == 0 { return "At \(event)" }
        let dir = template.defaultIsBeforeEvent ? "before" : "after"
        let mins = template.defaultOffsetMinutes
        let label = mins < 60 ? "\(mins) min" : (mins == 60 ? "1 hr" : "\(mins / 60) hr \(mins % 60) min")
        return "\(label) \(dir) \(event)"
    }
}

// MARK: - Weekday Chip Row

private struct WeekdayChipRow: View {
    @Binding var selection: WeekdaySelection

    private struct DayChip: Identifiable {
        let id: Int
        let day: WeekdaySelection
        let label: String
        let fullName: String
    }

    private let chips: [DayChip] = [
        DayChip(id: 0, day: .sunday,    label: "S", fullName: "Sunday"),
        DayChip(id: 1, day: .monday,    label: "M", fullName: "Monday"),
        DayChip(id: 2, day: .tuesday,   label: "T", fullName: "Tuesday"),
        DayChip(id: 3, day: .wednesday, label: "W", fullName: "Wednesday"),
        DayChip(id: 4, day: .thursday,  label: "T", fullName: "Thursday"),
        DayChip(id: 5, day: .friday,    label: "F", fullName: "Friday"),
        DayChip(id: 6, day: .saturday,  label: "S", fullName: "Saturday"),
    ]

    var body: some View {
        HStack(spacing: SunshiftSpacing.sm) {
            ForEach(chips) { chip in
                let isOn = selection.contains(chip.day)
                Button {
                    if isOn {
                        selection.remove(chip.day)
                    } else {
                        selection.insert(chip.day)
                    }
                } label: {
                    Text(chip.label)
                        .font(SunshiftTypography.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(isOn ? .white : SunshiftColors.secondaryText)
                        .frame(width: 36, height: 36)
                        .background(
                            isOn
                                ? AnyShapeStyle(SunshiftColors.sunsetAmber)
                                : AnyShapeStyle(SunshiftColors.softBackground),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: isOn)
                .accessibilityLabel(chip.fullName)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Create") {
    RoutineEditView(mode: .create, onSave: { _ in }, onCancel: { })
        .environment(SubscriptionService())
}

#Preview("Edit") {
    let routine = LightRoutine(
        title: "Sunset Walk",
        templateType: .sunsetWalk,
        sunEventType: .sunset,
        offsetMinutes: 30,
        isBeforeEvent: true,
        selectedWeekdays: .everyday,
        isEnabled: true,
        notificationMessage: "Time for your sunset walk."
    )
    RoutineEditView(mode: .edit(routine), onSave: { _ in }, onCancel: { })
        .environment(SubscriptionService())
}
