import Foundation

enum SubscriptionTier {
    case free
    case plus
}

// Templates available per tier
enum RoutineTemplate: String, CaseIterable, Identifiable, Codable {
    case sunsetWalk       = "Sunset Walk"
    case morningLight     = "Morning Light"
    case wakeBeforeSunrise = "Wake Before Sunrise"
    case goldenHourShoot  = "Golden Hour Shoot"
    case windDown         = "Wind Down"
    case lastLight        = "Last Light"

    var id: String { rawValue }

    var requiresPlus: Bool {
        switch self {
        case .sunsetWalk: return false
        case .morningLight, .wakeBeforeSunrise, .goldenHourShoot, .windDown, .lastLight: return true
        }
    }
}

// Free tier hard limits
enum FreeTierLimits {
    static let maxActiveRoutines = 1
    static let allowedTemplates: [RoutineTemplate] = [.sunsetWalk]
    static let previewDays = 0
    // Free users may save one home/manual location in addition to current location.
    static let maxSavedLocations = 1
}
