import Foundation

enum GeocodingError: Error, LocalizedError {
    case invalidCoordinates
    case noResultsFound
    case geocodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidCoordinates:
            return "The coordinates are outside the valid range."
        case .noResultsFound:
            return "No location information was found for these coordinates."
        case .geocodingFailed(let error):
            return "Geocoding failed: \(error.localizedDescription)"
        }
    }
}
