import Foundation

struct SunCalculationInput: Codable, Equatable {
    let date: Date
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
}
