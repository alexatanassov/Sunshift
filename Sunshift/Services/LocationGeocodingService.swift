import CoreLocation
import Foundation

// Converts raw coordinates into display-ready location data.
// Does not request location permissions; callers must supply coordinates.
protocol LocationGeocodingServiceProtocol: AnyObject {
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> GeocodedLocation
    func makeSavedLocation(from geocoded: GeocodedLocation, source: LocationSource) -> SavedLocation
}

final class LocationGeocodingService: LocationGeocodingServiceProtocol {

    private let geocoder = CLGeocoder()

    // MARK: - Reverse geocoding

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> GeocodedLocation {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw GeocodingError.invalidCoordinates
        }
        let clLocation = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
        } catch {
            throw GeocodingError.geocodingFailed(underlying: error)
        }
        guard let placemark = placemarks.first else {
            throw GeocodingError.noResultsFound
        }
        // Prefer the timezone embedded in the placemark; fall back to the device timezone
        // so callers always receive a valid identifier and never need to handle nil.
        let tzID = placemark.timeZone?.identifier ?? TimeZone.current.identifier
        return GeocodedLocation(
            latitude: latitude,
            longitude: longitude,
            city: placemark.locality,
            state: placemark.administrativeArea,
            country: placemark.country,
            isoCountryCode: placemark.isoCountryCode,
            timeZoneIdentifier: tzID
        )
    }

    // Convenience overload for the DeviceLocation -> GeocodedLocation pipeline.
    func reverseGeocode(_ deviceLocation: DeviceLocation) async throws -> GeocodedLocation {
        try await reverseGeocode(latitude: deviceLocation.latitude, longitude: deviceLocation.longitude)
    }

    // MARK: - Model construction

    func makeSavedLocation(from geocoded: GeocodedLocation, source: LocationSource) -> SavedLocation {
        SavedLocation(
            name: geocoded.locationName,
            subtitle: geocoded.displayName,
            latitude: geocoded.latitude,
            longitude: geocoded.longitude,
            timeZoneIdentifier: geocoded.timeZoneIdentifier,
            source: source,
            isCurrentLocation: source == .current
        )
    }
}
