import Foundation

@Observable
final class OnboardingViewModel {

    enum Step: Int, CaseIterable {
        case welcome      = 0
        case templatePick = 1
        case customize    = 2
        case confirm      = 3
    }

    private(set) var step: Step = .welcome
    private(set) var selectedTemplate: RoutineTemplate = .sunsetWalk
    // Non-nil when a Plus-locked template was tapped; drives the inline hint banner.
    private(set) var lockedTemplateHint: RoutineTemplate? = nil

    var offsetMinutes: Int
    var isBeforeEvent: Bool
    var selectedWeekdays: WeekdaySelection

    init() {
        let t = RoutineTemplate.sunsetWalk
        offsetMinutes = t.defaultOffsetMinutes
        isBeforeEvent = t.defaultIsBeforeEvent
        selectedWeekdays = .everyday
    }

    // MARK: - Navigation

    func advance() {
        guard let idx = Step.allCases.firstIndex(of: step),
              idx + 1 < Step.allCases.count else { return }
        step = Step.allCases[idx + 1]
    }

    func goBack() {
        guard let idx = Step.allCases.firstIndex(of: step), idx > 0 else { return }
        step = Step.allCases[idx - 1]
    }

    // MARK: - Template selection

    func selectTemplate(_ template: RoutineTemplate, isPlusUser: Bool) {
        guard isPlusUser || !template.requiresPlus else {
            lockedTemplateHint = template
            return
        }
        lockedTemplateHint = nil
        selectedTemplate = template
        offsetMinutes = template.defaultOffsetMinutes
        isBeforeEvent = template.defaultIsBeforeEvent
    }

    func dismissLockedHint() {
        lockedTemplateHint = nil
    }

    // MARK: - Build

    func buildRoutine() -> LightRoutine {
        LightRoutine(
            title: selectedTemplate.displayName,
            templateType: selectedTemplate,
            sunEventType: selectedTemplate.defaultSunEventType,
            offsetMinutes: offsetMinutes,
            isBeforeEvent: isBeforeEvent,
            selectedWeekdays: selectedWeekdays,
            isEnabled: true,
            notificationMessage: selectedTemplate.defaultNotificationMessage
        )
    }
}
