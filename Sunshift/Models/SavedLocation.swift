import Foundation

struct SavedLocation: Identifiable, Codable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String
    var isCurrentLocation: Bool

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        isCurrentLocation: Bool = false
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isCurrentLocation = isCurrentLocation
    }
}
