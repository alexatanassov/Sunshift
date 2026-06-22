import Foundation

enum SubscriptionTier {
    case free
    case plus
}

// Templates available per tier
enum RoutineTemplate: String, CaseIterable, Identifiable {
    case sunsetWalk = "Sunset Walk"
    case sunriseMeditation = "Sunrise Meditation"
    case goldenHourPhoto = "Golden Hour Photo"
    case morningLight = "Morning Light"

    var id: String { rawValue }

    var requiresPlus: Bool {
        switch self {
        case .sunsetWalk: return false
        case .sunriseMeditation, .goldenHourPhoto, .morningLight: return true
        }
    }
}

// Free tier hard limits
enum FreeTierLimits {
    static let maxActiveRoutines = 1
    static let allowedTemplates: [RoutineTemplate] = [.sunsetWalk]
    static let previewDays = 0
}
