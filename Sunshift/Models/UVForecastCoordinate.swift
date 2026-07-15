import Foundation

// A coordinate to request current UV Index data for.
nonisolated struct UVForecastCoordinate: Equatable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
