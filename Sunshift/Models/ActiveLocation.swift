import Foundation

// Persisted reference to whichever SavedLocation is currently selected for solar calculations.
// Stored separately so the full SavedLocation list and the active choice can be updated independently.
struct ActiveLocation: Codable {
    let locationID: UUID
    let setAt: Date
}
