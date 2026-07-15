import Foundation

// A single sampled UV Index reading at a coordinate, for a specific forecast time.
struct UVDataPoint: Identifiable, Codable, Equatable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let uvIndex: Double
    let time: Date

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        uvIndex: Double,
        time: Date
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.uvIndex = uvIndex
        self.time = time
    }

    var category: UVCategory {
        UVCategory(uvIndex: uvIndex)
    }
}
