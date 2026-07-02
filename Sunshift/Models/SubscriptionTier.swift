import Foundation

enum SubscriptionTier {
    case free
    case plus
}

enum RoutineTemplate: String, CaseIterable, Identifiable, Codable {
    case sunsetWalk      = "sunset_walk"
    case morningLight    = "morning_light"
    case windDown        = "wind_down"
    case goldenHourShoot = "golden_hour_shoot"
    case custom          = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sunsetWalk:      return "Sunset Walk"
        case .morningLight:    return "Morning Light"
        case .windDown:        return "Wind Down"
        case .goldenHourShoot: return "Golden Hour Shoot"
        case .custom:          return "Custom"
        }
    }

    var defaultSunEventType: SunEventType {
        switch self {
        case .sunsetWalk:      return .sunset
        case .morningLight:    return .sunrise
        case .windDown:        return .sunset
        case .goldenHourShoot: return .goldenHourStart
        case .custom:          return .sunset
        }
    }

    var defaultOffsetMinutes: Int {
        switch self {
        case .sunsetWalk:      return 30
        case .morningLight:    return 15
        case .windDown:        return 30
        case .goldenHourShoot: return 10
        case .custom:          return 0
        }
    }

    var defaultIsBeforeEvent: Bool {
        switch self {
        case .sunsetWalk:      return true
        case .morningLight:    return false
        case .windDown:        return false
        case .goldenHourShoot: return true
        case .custom:          return false
        }
    }

    var defaultNotificationMessage: String {
        switch self {
        case .sunsetWalk:      return "Time for your sunset walk."
        case .morningLight:    return "Good morning. Sunrise is here."
        case .windDown:        return "Sun's down. Time to wind down."
        case .goldenHourShoot: return "Golden hour starts soon. Get your camera ready."
        case .custom:          return ""
        }
    }

    var requiresPlus: Bool {
        switch self {
        case .sunsetWalk, .custom: return false
        case .morningLight, .windDown, .goldenHourShoot: return true
        }
    }
}

enum FreeTierLimits {
    static let maxActiveRoutines = 1
    static let allowedTemplates: [RoutineTemplate] = [.sunsetWalk, .custom]
    // Free users get the 7-day light preview.
    static let previewDays = 7
    static let maxSavedLocations = 1
}
