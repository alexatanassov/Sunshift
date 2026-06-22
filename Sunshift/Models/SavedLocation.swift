import Foundation

struct SavedLocation: Identifiable, Codable {
    let id: UUID
    var name: String
    var subtitle: String           // Locality text, e.g. "San Francisco, CA"
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String
    var source: LocationSource
    var isCurrentLocation: Bool
    var isHomeLocation: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String = "",
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        source: LocationSource = .manual,
        isCurrentLocation: Bool = false,
        isHomeLocation: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.source = source
        self.isCurrentLocation = isCurrentLocation
        self.isHomeLocation = isHomeLocation
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension SavedLocation {
    // Dev/first-launch fallback. Not a real user location.
    // Used only when no location has been set and the app needs coordinates to function.
    // source == .fallback distinguishes it from any real user location.
    static let devFallback = SavedLocation(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "San Diego",
        subtitle: "San Diego, CA",
        latitude: 32.7157,
        longitude: -117.1611,
        timeZoneIdentifier: "America/Los_Angeles",
        source: .fallback,
        isCurrentLocation: false,
        isHomeLocation: false,
        createdAt: .distantPast,
        updatedAt: .distantPast
    )
}
