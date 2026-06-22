import Foundation

enum SunEventType: String, CaseIterable, Identifiable, Codable {
    case sunrise
    case sunset
    case goldenHourStart
    case goldenHourEnd
    case blueHourStart
    case blueHourEnd
    case firstLight
    case lastLight
    case daylightRemaining

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sunrise:           return "Sunrise"
        case .sunset:            return "Sunset"
        case .goldenHourStart:   return "Golden Hour Start"
        case .goldenHourEnd:     return "Golden Hour End"
        case .blueHourStart:     return "Blue Hour Start"
        case .blueHourEnd:       return "Blue Hour End"
        case .firstLight:        return "First Light"
        case .lastLight:         return "Last Light"
        case .daylightRemaining: return "Daylight Remaining"
        }
    }
}
