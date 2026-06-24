import Foundation

enum SunEventType: String, CaseIterable, Identifiable, Codable {
    case sunrise
    case sunset
    case solarNoon
    case goldenHourStart
    case goldenHourEnd
    case blueHourStart
    case blueHourEnd
    case firstLight
    case lastLight
    case civilTwilightStart
    case civilTwilightEnd
    case daylightRemaining

    var id: String { rawValue }

    // daylightRemaining is a duration, not a point in time, so it cannot be used as a trigger.
    static var routineTriggerCases: [SunEventType] {
        allCases.filter { $0 != .daylightRemaining }
    }

    var displayName: String {
        switch self {
        case .sunrise:             return "Sunrise"
        case .sunset:              return "Sunset"
        case .solarNoon:           return "Solar Noon"
        case .goldenHourStart:     return "Golden Hour Start"
        case .goldenHourEnd:       return "Golden Hour End"
        case .blueHourStart:       return "Blue Hour Start"
        case .blueHourEnd:         return "Blue Hour End"
        case .firstLight:          return "First Light"
        case .lastLight:           return "Last Light"
        case .civilTwilightStart:  return "Civil Twilight Start"
        case .civilTwilightEnd:    return "Civil Twilight End"
        case .daylightRemaining:   return "Daylight Remaining"
        }
    }
}
