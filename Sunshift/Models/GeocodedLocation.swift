import Foundation

// Result of a reverse geocoding operation. Carries all raw components so callers
// can construct either a SavedLocation or display individual fields.
struct GeocodedLocation {
    let latitude: Double
    let longitude: Double
    let city: String?           // CLPlacemark.locality
    let state: String?          // CLPlacemark.administrativeArea (e.g., "CA")
    let country: String?        // CLPlacemark.country (e.g., "United States")
    let isoCountryCode: String? // CLPlacemark.isoCountryCode (e.g., "US")
    let timeZoneIdentifier: String

    // "San Diego, CA" / "Paris, France" / fallback.
    var displayName: String {
        Self.compactDisplayName(
            city: city, state: state, country: country, isoCountryCode: isoCountryCode
        )
    }

    // City name when available; falls back to the full display name.
    var locationName: String {
        city?.nonEmpty ?? displayName
    }
}

extension GeocodedLocation {
    // Builds a compact, human-readable location string from geocoding components.
    // US:            "San Diego, CA"
    // International: "Paris, France"
    // Degrades gracefully when components are absent or empty.
    static func compactDisplayName(
        city: String?,
        state: String?,
        country: String?,
        isoCountryCode: String?
    ) -> String {
        let city    = city?.nonEmpty
        let state   = state?.nonEmpty
        let country = country?.nonEmpty

        if let city, let state, isoCountryCode == "US" {
            return "\(city), \(state)"
        }
        if let city, let country {
            return "\(city), \(country)"
        }
        if let city {
            return city
        }
        if let state, let country {
            return "\(state), \(country)"
        }
        return country ?? "Unknown Location"
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
