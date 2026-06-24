import Foundation

@Observable
final class RoutineStore {
    private(set) var routines: [LightRoutine] = []

    private let userDefaults: UserDefaults
    private let key = "sunshift.light_routines"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    // MARK: - Mutations

    func add(_ routine: LightRoutine) {
        routines.append(routine)
        save()
    }

    func update(_ routine: LightRoutine) {
        guard let idx = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        var updated = routine
        updated.updatedAt = Date()
        routines[idx] = updated
        save()
    }

    func toggleEnabled(id: UUID) {
        guard let idx = routines.firstIndex(where: { $0.id == id }) else { return }
        routines[idx].isEnabled.toggle()
        routines[idx].updatedAt = Date()
        save()
    }

    func delete(id: UUID) {
        routines.removeAll { $0.id == id }
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = userDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([LightRoutine].self, from: data)
        else { return }
        routines = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(routines) else { return }
        userDefaults.set(data, forKey: key)
    }

}
