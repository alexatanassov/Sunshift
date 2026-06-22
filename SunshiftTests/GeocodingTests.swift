import Testing
import Foundation
@testable import Sunshift

// Tests cover only pure formatting and model-construction logic.
// Network-dependent reverse geocoding is intentionally excluded.
struct GeocodingTests {

    // MARK: - compactDisplayName: US

    @Test func usLocationShowsCityAndState() {
        let name = GeocodedLocation.compactDisplayName(
            city: "San Diego", state: "CA", country: "United States", isoCountryCode: "US"
        )
        #expect(name == "San Diego, CA")
    }

    @Test func usLocationWithoutStateShowsCityAndCountry() {
        let name = GeocodedLocation.compactDisplayName(
            city: "San Diego", state: nil, country: "United States", isoCountryCode: "US"
        )
        #expect(name == "San Diego, United States")
    }

    // MARK: - compactDisplayName: international

    @Test func internationalLocationShowsCityAndCountry() {
        let name = GeocodedLocation.compactDisplayName(
            city: "Paris", state: "Ile-de-France", country: "France", isoCountryCode: "FR"
        )
        #expect(name == "Paris, France")
    }

    @Test func nonUSCountryDoesNotUseStateAbbreviation() {
        let name = GeocodedLocation.compactDisplayName(
            city: "Toronto", state: "ON", country: "Canada", isoCountryCode: "CA"
        )
        #expect(name == "Toronto, Canada")
    }

    // MARK: - compactDisplayName: partial data

    @Test func cityOnlyWhenNoStateOrCountry() {
        let name = GeocodedLocation.compactDisplayName(
            city: "Madrid", state: nil, country: nil, isoCountryCode: "ES"
        )
        #expect(name == "Madrid")
    }

    @Test func stateAndCountryWhenNoCityInternational() {
        let name = GeocodedLocation.compactDisplayName(
            city: nil, state: "Bavaria", country: "Germany", isoCountryCode: "DE"
        )
        #expect(name == "Bavaria, Germany")
    }

    @Test func countryOnlyWhenNoCityOrState() {
        let name = GeocodedLocation.compactDisplayName(
            city: nil, state: nil, country: "Iceland", isoCountryCode: "IS"
        )
        #expect(name == "Iceland")
    }

    // MARK: - compactDisplayName: empty / nil

    @Test func unknownLocationWhenAllNil() {
        let name = GeocodedLocation.compactDisplayName(
            city: nil, state: nil, country: nil, isoCountryCode: nil
        )
        #expect(name == "Unknown Location")
    }

    @Test func emptyStringsAreTreatedAsNil() {
        let name = GeocodedLocation.compactDisplayName(
            city: "", state: "", country: "", isoCountryCode: "US"
        )
        #expect(name == "Unknown Location")
    }

    @Test func emptyCityFallsBackToCountry() {
        let name = GeocodedLocation.compactDisplayName(
            city: "", state: nil, country: "Japan", isoCountryCode: "JP"
        )
        #expect(name == "Japan")
    }

    // MARK: - GeocodedLocation.displayName

    @Test func displayNameDerivedFromComponents() {
        let location = GeocodedLocation(
            latitude: 32.7157,
            longitude: -117.1611,
            city: "San Diego",
            state: "CA",
            country: "United States",
            isoCountryCode: "US",
            timeZoneIdentifier: "America/Los_Angeles"
        )
        #expect(location.displayName == "San Diego, CA")
    }

    // MARK: - GeocodedLocation.locationName

    @Test func locationNameReturnsCityWhenPresent() {
        let location = GeocodedLocation(
            latitude: 48.8566,
            longitude: 2.3522,
            city: "Paris",
            state: "Ile-de-France",
            country: "France",
            isoCountryCode: "FR",
            timeZoneIdentifier: "Europe/Paris"
        )
        #expect(location.locationName == "Paris")
    }

    @Test func locationNameFallsBackToDisplayNameWhenNoCityPresent() {
        let location = GeocodedLocation(
            latitude: 64.1355,
            longitude: -21.8954,
            city: nil,
            state: nil,
            country: "Iceland",
            isoCountryCode: "IS",
            timeZoneIdentifier: "Atlantic/Reykjavik"
        )
        #expect(location.locationName == "Iceland")
    }

    @Test func locationNameFallsBackToDisplayNameWhenCityEmpty() {
        let location = GeocodedLocation(
            latitude: 64.1355,
            longitude: -21.8954,
            city: "",
            state: nil,
            country: "Iceland",
            isoCountryCode: "IS",
            timeZoneIdentifier: "Atlantic/Reykjavik"
        )
        #expect(location.locationName == "Iceland")
    }

    // MARK: - makeSavedLocation

    @Test func makeSavedLocationPopulatesAllFields() {
        let service = LocationGeocodingService()
        let geocoded = GeocodedLocation(
            latitude: 48.8566,
            longitude: 2.3522,
            city: "Paris",
            state: "Ile-de-France",
            country: "France",
            isoCountryCode: "FR",
            timeZoneIdentifier: "Europe/Paris"
        )
        let saved = service.makeSavedLocation(from: geocoded, source: .searchResult)
        #expect(saved.name == "Paris")
        #expect(saved.subtitle == "Paris, France")
        #expect(saved.latitude == 48.8566)
        #expect(saved.longitude == 2.3522)
        #expect(saved.timeZoneIdentifier == "Europe/Paris")
        #expect(saved.source == .searchResult)
        #expect(!saved.isCurrentLocation)
    }

    @Test func makeSavedLocationSetsIsCurrentLocationForCurrentSource() {
        let service = LocationGeocodingService()
        let geocoded = GeocodedLocation(
            latitude: 37.7749,
            longitude: -122.4194,
            city: "San Francisco",
            state: "CA",
            country: "United States",
            isoCountryCode: "US",
            timeZoneIdentifier: "America/Los_Angeles"
        )
        let saved = service.makeSavedLocation(from: geocoded, source: .current)
        #expect(saved.isCurrentLocation)
        #expect(saved.source == .current)
    }

    @Test func makeSavedLocationDoesNotSetIsCurrentForManualSource() {
        let service = LocationGeocodingService()
        let geocoded = GeocodedLocation(
            latitude: 51.5074,
            longitude: -0.1278,
            city: "London",
            state: nil,
            country: "United Kingdom",
            isoCountryCode: "GB",
            timeZoneIdentifier: "Europe/London"
        )
        let saved = service.makeSavedLocation(from: geocoded, source: .manual)
        #expect(!saved.isCurrentLocation)
        #expect(saved.source == .manual)
    }

    @Test func makeSavedLocationNameFallsBackWhenNoCityPresent() {
        let service = LocationGeocodingService()
        let geocoded = GeocodedLocation(
            latitude: 64.1355,
            longitude: -21.8954,
            city: nil,
            state: nil,
            country: "Iceland",
            isoCountryCode: "IS",
            timeZoneIdentifier: "Atlantic/Reykjavik"
        )
        let saved = service.makeSavedLocation(from: geocoded, source: .manual)
        #expect(saved.name == "Iceland")
        #expect(saved.subtitle == "Iceland")
    }
}
