import Foundation

// UV Index severity band, based on the standard WHO/EPA UV Index scale.
// Purely descriptive: carries a label only, never advice or safety recommendation text.
nonisolated enum UVCategory: String, CaseIterable, Identifiable, Codable {
    case low
    case moderate
    case high
    case veryHigh
    case extreme

    var id: String { rawValue }

    // Standard UV Index bands: Low 0-2, Moderate 3-5, High 6-7, Very High 8-10, Extreme 11+.
    // Values below 0 are treated as Low rather than rejected, since forecast data can round
    // slightly negative near zero.
    init(uvIndex: Double) {
        switch uvIndex {
        case ..<3:   self = .low
        case 3..<6:  self = .moderate
        case 6..<8:  self = .high
        case 8..<11: self = .veryHigh
        default:     self = .extreme
        }
    }

    var displayName: String {
        switch self {
        case .low:      return "Low"
        case .moderate: return "Moderate"
        case .high:     return "High"
        case .veryHigh: return "Very High"
        case .extreme:  return "Extreme"
        }
    }
}
