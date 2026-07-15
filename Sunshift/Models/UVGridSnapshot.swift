import Foundation

// A saved set of UV Map grid points for one region, captured at a point in time.
// Lets the UV Map show recently fetched data without immediately refetching.
struct UVGridSnapshot: Codable, Equatable {
    let points: [UVDataPoint]
    let regionKey: String
    let fetchedAt: Date

    enum Freshness {
        case fresh
        case staleButUsable
        case expired
    }

    static let freshInterval: TimeInterval = 30 * 60
    static let staleInterval: TimeInterval = 24 * 60 * 60

    // - `fresh` if under 30 minutes old.
    // - `staleButUsable` if under 24 hours old (safe to show while a refetch happens).
    // - `expired` at or past 24 hours old.
    func freshness(asOf now: Date = Date()) -> Freshness {
        let age = now.timeIntervalSince(fetchedAt)
        if age < Self.freshInterval { return .fresh }
        if age < Self.staleInterval { return .staleButUsable }
        return .expired
    }
}
