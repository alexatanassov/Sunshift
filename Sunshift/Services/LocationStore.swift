import Foundation

@Observable
final class LocationStore {

    // MARK: - Published state

    private(set) var savedLocations: [SavedLocation] = []
    private(set) var activeLocation: SavedLocation?

    // MARK: - UserDefaults keys

    private enum Keys {
        static let savedLocations  = "sunshift.savedLocations"
        static let activeLocationID = "sunshift.activeLocationID"
    }

    // MARK: - Init

    init() {
        loadSavedLocations()
        loadActiveLocation()
    }

    // MARK: - Load

    func loadSavedLocations() {
        guard
            let data = UserDefaults.standard.data(forKey: Keys.savedLocations),
            let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data)
        else {
            savedLocations = []
            return
        }
        savedLocations = decoded
    }

    func loadActiveLocation() {
        guard
            let idString = UserDefaults.standard.string(forKey: Keys.activeLocationID),
            let id = UUID(uuidString: idString)
        else {
            activeLocation = nil
            return
        }
        activeLocation = savedLocations.first(where: { $0.id == id })
    }

    // MARK: - Mutate saved locations

    func add(_ location: SavedLocation) {
        savedLocations.append(location)
        persistSavedLocations()
    }

    func update(_ location: SavedLocation) {
        guard let index = savedLocations.firstIndex(where: { $0.id == location.id }) else { return }
        savedLocations[index] = location
        persistSavedLocations()
        if activeLocation?.id == location.id {
            activeLocation = location
        }
    }

    func remove(id: UUID) {
        savedLocations.removeAll(where: { $0.id == id })
        persistSavedLocations()
        if activeLocation?.id == id {
            clearActiveLocation()
        }
    }

    // MARK: - Active location

    func setActiveLocation(_ location: SavedLocation) {
        activeLocation = location
        UserDefaults.standard.set(location.id.uuidString, forKey: Keys.activeLocationID)
    }

    func clearActiveLocation() {
        activeLocation = nil
        UserDefaults.standard.removeObject(forKey: Keys.activeLocationID)
    }

    // MARK: - Resolved location

    // The location to use for solar calculations.
    // Falls back to devFallback when nothing has been set; callers should check isUsingFallback
    // to surface appropriate UI rather than silently showing fallback data as real.
    var resolvedLocation: SavedLocation {
        activeLocation ?? .devFallback
    }

    var isUsingFallback: Bool {
        activeLocation == nil || activeLocation?.source == .fallback
    }

    // MARK: - Feature gate helpers

    // Returns whether the user may save an additional non-current location given their tier.
    func canAddSavedLocation(tier: SubscriptionTier) -> Bool {
        if tier == .plus { return true }
        let nonCurrentCount = savedLocations.filter { !$0.isCurrentLocation }.count
        return nonCurrentCount < FreeTierLimits.maxSavedLocations
    }

    // MARK: - Private

    private func persistSavedLocations() {
        guard let data = try? JSONEncoder().encode(savedLocations) else { return }
        UserDefaults.standard.set(data, forKey: Keys.savedLocations)
    }
}
