import Testing
import Foundation
@testable import Sunshift

struct RoutinesViewModelTests {

    // Each test gets its own isolated UserDefaults suite so persistence doesn't bleed.
    private func makeViewModel(isPlusUser: Bool = false) -> RoutinesViewModel {
        let defaults = UserDefaults(suiteName: "sunshift.test.\(UUID().uuidString)")!
        let store = RoutineStore(userDefaults: defaults)
        let sub = SubscriptionService()
        sub.isPlusUser = isPlusUser
        return RoutinesViewModel(store: store, subscriptionService: sub)
    }

    // Returns a fresh VM+Store pair so tests can inspect the store directly.
    private func makeViewModelAndStore(isPlusUser: Bool = false) -> (RoutinesViewModel, RoutineStore) {
        let defaults = UserDefaults(suiteName: "sunshift.test.\(UUID().uuidString)")!
        let store = RoutineStore(userDefaults: defaults)
        let sub = SubscriptionService()
        sub.isPlusUser = isPlusUser
        return (RoutinesViewModel(store: store, subscriptionService: sub), store)
    }

    // MARK: - triggerDescription

    @Test func triggerDescriptionAtEvent() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, offsetMinutes: 0)
        #expect(vm.triggerDescription(for: routine) == "At Sunset")
    }

    @Test func triggerDescriptionAtSunrise() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunrise, offsetMinutes: 0)
        #expect(vm.triggerDescription(for: routine) == "At Sunrise")
    }

    @Test func triggerDescriptionMinutesBeforeEvent() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, offsetMinutes: 30, isBeforeEvent: true)
        #expect(vm.triggerDescription(for: routine) == "30 min before Sunset")
    }

    @Test func triggerDescriptionMinutesAfterEvent() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunrise, offsetMinutes: 15, isBeforeEvent: false)
        #expect(vm.triggerDescription(for: routine) == "15 min after Sunrise")
    }

    @Test func triggerDescriptionOneHourBefore() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, offsetMinutes: 60, isBeforeEvent: true)
        #expect(vm.triggerDescription(for: routine) == "1 hr before Sunset")
    }

    @Test func triggerDescriptionTwoHours() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, offsetMinutes: 120, isBeforeEvent: false)
        #expect(vm.triggerDescription(for: routine) == "2 hrs after Sunset")
    }

    @Test func triggerDescriptionHoursAndMinutes() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, offsetMinutes: 90, isBeforeEvent: true)
        #expect(vm.triggerDescription(for: routine) == "1 hr 30 min before Sunset")
    }

    @Test func triggerDescriptionGoldenHour() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .goldenHourStart, offsetMinutes: 10, isBeforeEvent: true)
        #expect(vm.triggerDescription(for: routine) == "10 min before Golden Hour Start")
    }

    // MARK: - activeDaysSummary

    @Test func activeDaysSummaryEveryDay() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, selectedWeekdays: .everyday)
        #expect(vm.activeDaysSummary(for: routine) == "Every day")
    }

    @Test func activeDaysSummaryWeekdays() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, selectedWeekdays: .weekdays)
        #expect(vm.activeDaysSummary(for: routine) == "Weekdays")
    }

    @Test func activeDaysSummaryWeekends() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, selectedWeekdays: .weekends)
        #expect(vm.activeDaysSummary(for: routine) == "Weekends")
    }

    @Test func activeDaysSummaryCustomDays() {
        let vm = makeViewModel()
        let days: WeekdaySelection = [.monday, .wednesday, .friday]
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, selectedWeekdays: days)
        #expect(vm.activeDaysSummary(for: routine) == "Mon, Wed, Fri")
    }

    @Test func activeDaysSummaryNeverWhenEmpty() {
        let vm = makeViewModel()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, selectedWeekdays: WeekdaySelection(rawValue: 0))
        #expect(vm.activeDaysSummary(for: routine) == "Never")
    }

    // MARK: - Free tier limit

    @Test func freeUserAtLimitCannotAdd() {
        let (vm, store) = makeViewModelAndStore(isPlusUser: false)
        let first = LightRoutine(title: "First", sunEventType: .sunset)
        vm.addRoutine(first)
        #expect(store.routines.count == 1)
        #expect(!vm.canAddRoutine)
        #expect(vm.isAtFreeLimit)

        let extra = LightRoutine(title: "Extra", sunEventType: .sunrise)
        vm.addRoutine(extra)
        #expect(store.routines.count == 1, "Routine count must not change when at free limit")
    }

    @Test func freeUserWithNoRoutinesCanAddOne() {
        let vm = makeViewModel(isPlusUser: false)
        #expect(vm.routines.isEmpty)
        #expect(vm.canAddRoutine)
        #expect(!vm.isAtFreeLimit)

        let routine = LightRoutine(title: "My First", sunEventType: .sunset)
        vm.addRoutine(routine)
        #expect(vm.routines.count == 1)
        #expect(!vm.canAddRoutine, "Should be at limit after adding one")
    }

    @Test func plusUserCanAddBeyondFreeLimit() {
        let (vm, store) = makeViewModelAndStore(isPlusUser: true)
        let first = LightRoutine(title: "First Routine", sunEventType: .sunset)
        vm.addRoutine(first)
        #expect(store.routines.count == 1)
        #expect(vm.canAddRoutine)
        #expect(!vm.isAtFreeLimit)

        let extra = LightRoutine(title: "Second Routine", sunEventType: .sunrise)
        vm.addRoutine(extra)
        #expect(store.routines.count == 2)
    }

    // MARK: - Editing updates the store

    @Test func editingRoutineUpdatesStoreTitle() {
        let (vm, store) = makeViewModelAndStore()
        let original = LightRoutine(title: "Original", sunEventType: .sunset)
        vm.addRoutine(original)
        var updated = original
        updated.title = "Evening Golden Hour"
        vm.updateRoutine(updated)
        #expect(store.routines[0].title == "Evening Golden Hour")
    }

    @Test func editingRoutineUpdatesEventType() {
        let (vm, store) = makeViewModelAndStore()
        let original = LightRoutine(title: "Walk", sunEventType: .sunset)
        vm.addRoutine(original)
        var updated = original
        updated.sunEventType = .goldenHourStart
        vm.updateRoutine(updated)
        #expect(store.routines[0].sunEventType == .goldenHourStart)
    }

    @Test func editingRoutinePreservesId() {
        let (vm, store) = makeViewModelAndStore()
        let original = LightRoutine(title: "Original", sunEventType: .sunset)
        vm.addRoutine(original)
        let originalId = original.id
        var updated = original
        updated.title = "Changed"
        vm.updateRoutine(updated)
        #expect(store.routines[0].id == originalId)
    }

    // MARK: - Toggle

    @Test func toggleEnabledFlipsState() {
        let (vm, store) = makeViewModelAndStore()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, isEnabled: true)
        vm.addRoutine(routine)
        let id = store.routines[0].id
        let wasEnabled = store.routines[0].isEnabled
        vm.toggleEnabled(for: id)
        #expect(store.routines[0].isEnabled == !wasEnabled)
    }

    // MARK: - Add from template

    @Test func addFromTemplateCreatesExpectedDefaults() throws {
        let (vm, store) = makeViewModelAndStore(isPlusUser: true)

        let template = RoutineTemplate.morningLight
        let routine = LightRoutine(
            title: template.displayName,
            templateType: template,
            sunEventType: template.defaultSunEventType,
            offsetMinutes: template.defaultOffsetMinutes,
            isBeforeEvent: template.defaultIsBeforeEvent,
            selectedWeekdays: .everyday,
            isEnabled: true,
            notificationMessage: template.defaultNotificationMessage
        )
        vm.addRoutine(routine)

        let added = try #require(store.routines.first(where: { $0.templateType == .morningLight }))
        #expect(added.title == "Morning Light")
        #expect(added.sunEventType == .sunrise)
        #expect(added.offsetMinutes == 15)
        #expect(added.isBeforeEvent == false)
        #expect(added.selectedWeekdays == .everyday)
        #expect(added.isEnabled == true)
        #expect(added.notificationMessage == "Good morning. Sunrise is here.")
    }

    // MARK: - Onboarding upsert

    @Test func upsertOnboardingRoutineUpdatesExistingRoutineInPlace() {
        let (vm, store) = makeViewModelAndStore()
        let existing = LightRoutine(title: "Original Walk", sunEventType: .sunset)
        store.add(existing)
        #expect(store.routines.count == 1)

        let built = LightRoutine(title: "Custom Walk", sunEventType: .goldenHourStart, offsetMinutes: 10, isBeforeEvent: true)
        vm.upsertOnboardingRoutine(built)

        #expect(store.routines.count == 1, "Must update, not add a second routine")
        #expect(store.routines[0].title == "Custom Walk")
        #expect(store.routines[0].sunEventType == .goldenHourStart)
        #expect(store.routines[0].offsetMinutes == 10)
    }

    @Test func upsertOnboardingRoutineAddsWhenStoreIsEmpty() {
        let vm = makeViewModel()
        #expect(vm.routines.isEmpty)
        let built = LightRoutine(title: "Fresh Start", sunEventType: .sunset)
        vm.upsertOnboardingRoutine(built)
        #expect(vm.routines.count == 1)
        #expect(vm.routines[0].title == "Fresh Start")
    }

    // MARK: - Upcoming routine preview

    private func makeSFLocation() -> SavedLocation {
        SavedLocation(
            name: "San Francisco",
            subtitle: "San Francisco, CA",
            latitude: 37.7749,
            longitude: -122.4194,
            timeZoneIdentifier: "America/Los_Angeles",
            source: .manual,
            isCurrentLocation: false
        )
    }

    private func makeNoon(year: Int = 2026, month: Int = 6, day: Int = 23) throws -> Date {
        let tz = try #require(TimeZone(identifier: "America/Los_Angeles"))
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        var dc = DateComponents()
        dc.year = year; dc.month = month; dc.day = day; dc.hour = 12
        return try #require(cal.date(from: dc))
    }

    @Test func upcomingRoutinePreviewNilWhenNoRoutines() throws {
        let vm = makeViewModel()
        let now = try makeNoon()
        #expect(vm.upcomingRoutinePreview(location: makeSFLocation(), now: now) == nil)
    }

    @Test func upcomingRoutinePreviewNilWhenAllRoutinesDisabled() throws {
        let (vm, _) = makeViewModelAndStore()
        let routine = LightRoutine(title: "Sunset Walk", sunEventType: .sunset, offsetMinutes: 30, isBeforeEvent: true, isEnabled: false)
        vm.addRoutine(routine)
        let now = try makeNoon()
        #expect(vm.upcomingRoutinePreview(location: makeSFLocation(), now: now) == nil)
    }

    @Test func upcomingRoutinePreviewReturnsSoonestRoutine() throws {
        let (vm, _) = makeViewModelAndStore(isPlusUser: true)
        // Sunset is around 8:30 PM in SF in late June, so a 30-min-before trigger is the sooner one.
        let soon = LightRoutine(title: "Sunset Walk", sunEventType: .sunset, offsetMinutes: 30, isBeforeEvent: true, isEnabled: true)
        let later = LightRoutine(title: "Late Night Read", sunEventType: .lastLight, offsetMinutes: 0, isEnabled: true)
        vm.addRoutine(soon)
        vm.addRoutine(later)

        let now = try makeNoon()
        let preview = try #require(vm.upcomingRoutinePreview(location: makeSFLocation(), now: now))
        #expect(preview.routineTitle == "Sunset Walk")
        #expect(preview.summary == "30 min before Sunset, Every day")
        #expect(preview.countdownText.range(of: #"^(\d+h )?\d+m \d{2}s$|^\d+s$"#, options: .regularExpression) != nil)
    }

    // MARK: - Delete

    @Test func deleteRemovesRoutineFromStore() {
        let (vm, store) = makeViewModelAndStore(isPlusUser: true)
        let keeper = LightRoutine(title: "Keeper", sunEventType: .sunset)
        let extra = LightRoutine(title: "Ephemeral", sunEventType: .sunrise)
        vm.addRoutine(keeper)
        vm.addRoutine(extra)
        #expect(store.routines.count == 2)

        vm.deleteRoutine(id: extra.id)
        #expect(store.routines.count == 1)
        #expect(!store.routines.contains(where: { $0.id == extra.id }))
    }
}
