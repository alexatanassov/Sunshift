import Foundation

// Single source of truth for the UV Map's local radius: how far around the active
// coordinate the map is meant to represent. Both the sampling grid's span and the heat
// overlay's visible radius derive from this constant, so they can't drift out of sync, and
// the radius can be retuned (e.g. to 20 or 30 miles) in one place.
nonisolated enum UVMapRadiusConfig {
    static let defaultRadiusMiles: Double = 25

    // Rough miles-per-degree-of-latitude used to convert a radius in miles to a map span in
    // degrees. Good enough for sizing a local sampling region; not intended for precise
    // geodesy.
    static let milesPerDegreeLatitude: Double = 69.0

    // The span (edge to edge) of a square region that covers a circle of the given radius,
    // in degrees. Used as the sampling grid's span so it stays proportional to the radius
    // instead of an unrelated hardcoded degree value.
    static func spanDegrees(forRadiusMiles radiusMiles: Double = defaultRadiusMiles) -> Double {
        (radiusMiles * 2) / milesPerDegreeLatitude
    }

    static let defaultSpanDegrees: Double = spanDegrees(forRadiusMiles: defaultRadiusMiles)
}
