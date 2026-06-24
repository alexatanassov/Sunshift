import Testing
import Foundation
@testable import Sunshift

struct OnboardingViewModelTests {

    // MARK: - Initial state

    @Test func defaultsToWelcomeStep() {
        let vm = OnboardingViewModel()
        #expect(vm.step == .welcome)
    }

    @Test func defaultsToSunsetWalkTemplate() {
        let vm = OnboardingViewModel()
        #expect(vm.selectedTemplate == .sunsetWalk)
    }

    @Test func defaultsMatchSunsetWalkPresets() {
        let vm = OnboardingViewModel()
        #expect(vm.offsetMinutes == RoutineTemplate.sunsetWalk.defaultOffsetMinutes)
        #expect(vm.isBeforeEvent == RoutineTemplate.sunsetWalk.defaultIsBeforeEvent)
        #expect(vm.selectedWeekdays == .everyday)
    }

    @Test func defaultLockedHintIsNil() {
        let vm = OnboardingViewModel()
        #expect(vm.lockedTemplateHint == nil)
    }

    // MARK: - Navigation

    @Test func advanceProgressesThroughAllSteps() {
        let vm = OnboardingViewModel()
        #expect(vm.step == .welcome)
        vm.advance()
        #expect(vm.step == .templatePick)
        vm.advance()
        #expect(vm.step == .customize)
        vm.advance()
        #expect(vm.step == .location)
        vm.advance()
        #expect(vm.step == .confirm)
        vm.advance()
        #expect(vm.step == .notifications)
    }

    @Test func advanceDoesNotPassLastStep() {
        let vm = OnboardingViewModel()
        OnboardingViewModel.Step.allCases.forEach { _ in vm.advance() }
        #expect(vm.step == .notifications)
        vm.advance()
        #expect(vm.step == .notifications)
    }

    @Test func stepCountIsCorrect() {
        #expect(OnboardingViewModel.Step.allCases.count == 6)
    }

    @Test func goBackDecrementsStep() {
        let vm = OnboardingViewModel()
        vm.advance()
        vm.advance()
        #expect(vm.step == .customize)
        vm.goBack()
        #expect(vm.step == .templatePick)
    }

    @Test func goBackDoesNotPassFirstStep() {
        let vm = OnboardingViewModel()
        #expect(vm.step == .welcome)
        vm.goBack()
        #expect(vm.step == .welcome)
    }

    // MARK: - Template selection

    @Test func selectFreeTemplateAsNonPlusSucceeds() {
        let vm = OnboardingViewModel()
        vm.selectTemplate(.sunsetWalk, isPlusUser: false)
        #expect(vm.selectedTemplate == .sunsetWalk)
        #expect(vm.lockedTemplateHint == nil)
    }

    @Test func selectLockedTemplateAsNonPlusDoesNotChangeSelection() {
        let vm = OnboardingViewModel()
        vm.selectTemplate(.morningLight, isPlusUser: false)
        #expect(vm.selectedTemplate == .sunsetWalk)
        #expect(vm.lockedTemplateHint == .morningLight)
    }

    @Test func selectLockedTemplateAsPlusUserSucceeds() {
        let vm = OnboardingViewModel()
        vm.selectTemplate(.morningLight, isPlusUser: true)
        #expect(vm.selectedTemplate == .morningLight)
        #expect(vm.lockedTemplateHint == nil)
    }

    @Test func selectTemplateAppliesDefaultOffset() {
        let vm = OnboardingViewModel()
        vm.selectTemplate(.morningLight, isPlusUser: true)
        #expect(vm.offsetMinutes == RoutineTemplate.morningLight.defaultOffsetMinutes)
        #expect(vm.isBeforeEvent == RoutineTemplate.morningLight.defaultIsBeforeEvent)
    }

    @Test func selectFreeTemplateAfterLockedDismissesHint() {
        let vm = OnboardingViewModel()
        vm.selectTemplate(.morningLight, isPlusUser: false)
        #expect(vm.lockedTemplateHint != nil)
        vm.selectTemplate(.sunsetWalk, isPlusUser: false)
        #expect(vm.lockedTemplateHint == nil)
    }

    @Test func dismissLockedHintClearsHint() {
        let vm = OnboardingViewModel()
        vm.selectTemplate(.morningLight, isPlusUser: false)
        #expect(vm.lockedTemplateHint != nil)
        vm.dismissLockedHint()
        #expect(vm.lockedTemplateHint == nil)
        #expect(vm.selectedTemplate == .sunsetWalk)
    }

    // MARK: - buildRoutine

    @Test func buildRoutineReflectsDefaultSunsetWalk() {
        let vm = OnboardingViewModel()
        let routine = vm.buildRoutine()
        #expect(routine.title == "Sunset Walk")
        #expect(routine.templateType == .sunsetWalk)
        #expect(routine.sunEventType == .sunset)
        #expect(routine.offsetMinutes == 30)
        #expect(routine.isBeforeEvent == true)
        #expect(routine.selectedWeekdays == .everyday)
        #expect(routine.isEnabled == true)
        #expect(routine.notificationMessage == RoutineTemplate.sunsetWalk.defaultNotificationMessage)
    }

    @Test func buildRoutineReflectsCustomizedOffset() {
        let vm = OnboardingViewModel()
        vm.offsetMinutes = 15
        vm.isBeforeEvent = false
        let routine = vm.buildRoutine()
        #expect(routine.offsetMinutes == 15)
        #expect(routine.isBeforeEvent == false)
    }

    @Test func buildRoutineReflectsCustomizedWeekdays() {
        let vm = OnboardingViewModel()
        vm.selectedWeekdays = .weekdays
        let routine = vm.buildRoutine()
        #expect(routine.selectedWeekdays == .weekdays)
    }

    @Test func buildRoutineReflectsSelectedTemplate() throws {
        let vm = OnboardingViewModel()
        vm.selectTemplate(.morningLight, isPlusUser: true)
        let routine = vm.buildRoutine()
        #expect(routine.title == "Morning Light")
        #expect(routine.templateType == .morningLight)
        #expect(routine.sunEventType == .sunrise)
    }
}
