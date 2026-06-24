import Testing
import Foundation
@testable import Sunshift

struct RoutineStoreTests {

    // MARK: - Helpers

    private func makeFreshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "sunshift.storetest.\(UUID().uuidString)")!
    }

    private func makeEmptyStore() -> (RoutineStore, UserDefaults) {
        let defaults = makeFreshDefaults()
        return (RoutineStore(userDefaults: defaults), defaults)
    }

    // MARK: - Initial state

    @Test func freshStoreStartsEmpty() {
        let store = RoutineStore(userDefaults: makeFreshDefaults())
        #expect(store.routines.isEmpty)
    }

    // MARK: - Persistence

    @Test func addPersists() {
        let (store, defaults) = makeEmptyStore()
        let routine = LightRoutine(title: "Evening Walk", sunEventType: .sunset)
        store.add(routine)

        let store2 = RoutineStore(userDefaults: defaults)
        #expect(store2.routines.count == 1)
        #expect(store2.routines[0].title == "Evening Walk")
        #expect(store2.routines[0].id == routine.id)
    }

    @Test func updatePersists() {
        let (store, defaults) = makeEmptyStore()
        let routine = LightRoutine(title: "Walk", sunEventType: .sunset)
        store.add(routine)

        var updated = routine
        updated.title = "Golden Walk"
        updated.sunEventType = .goldenHourStart
        store.update(updated)

        let store2 = RoutineStore(userDefaults: defaults)
        #expect(store2.routines.count == 1)
        #expect(store2.routines[0].title == "Golden Walk")
        #expect(store2.routines[0].sunEventType == .goldenHourStart)
    }

    @Test func deletePersists() {
        let (store, defaults) = makeEmptyStore()
        let r1 = LightRoutine(title: "First", sunEventType: .sunset)
        let r2 = LightRoutine(title: "Second", sunEventType: .sunrise)
        store.add(r1)
        store.add(r2)
        #expect(store.routines.count == 2)

        store.delete(id: r1.id)

        let store2 = RoutineStore(userDefaults: defaults)
        #expect(store2.routines.count == 1)
        #expect(store2.routines[0].title == "Second")
        #expect(!store2.routines.contains(where: { $0.id == r1.id }))
    }

    @Test func toggleEnabledPersists() {
        let (store, defaults) = makeEmptyStore()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, isEnabled: true)
        store.add(routine)

        store.toggleEnabled(id: routine.id)
        #expect(store.routines[0].isEnabled == false)

        let store2 = RoutineStore(userDefaults: defaults)
        #expect(store2.routines[0].isEnabled == false, "Disabled state must survive a reload")
    }

    @Test func toggleEnabledBackToEnabledPersists() {
        let (store, defaults) = makeEmptyStore()
        let routine = LightRoutine(title: "Test", sunEventType: .sunset, isEnabled: true)
        store.add(routine)

        store.toggleEnabled(id: routine.id)
        store.toggleEnabled(id: routine.id)
        #expect(store.routines[0].isEnabled == true)

        let store2 = RoutineStore(userDefaults: defaults)
        #expect(store2.routines[0].isEnabled == true)
    }

    // MARK: - Identity

    @Test func updatePreservesId() {
        let (store, _) = makeEmptyStore()
        let routine = LightRoutine(title: "Original", sunEventType: .sunset)
        store.add(routine)

        var updated = routine
        updated.title = "Changed"
        store.update(updated)

        #expect(store.routines[0].id == routine.id)
    }

    @Test func unknownIdUpdateIsNoOp() {
        let (store, _) = makeEmptyStore()
        let routine = LightRoutine(title: "Keep", sunEventType: .sunset)
        store.add(routine)

        let ghost = LightRoutine(title: "Ghost", sunEventType: .sunrise)
        store.update(ghost)

        #expect(store.routines.count == 1)
        #expect(store.routines[0].title == "Keep")
    }
}
