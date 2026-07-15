import Testing
import Foundation
@testable import Sunshift

private func makeSavedLocation(
    latitude: Double = 37.7749,
    longitude: Double = -122.4194,
    source: LocationSource = .manual
) -> SavedLocation {
    SavedLocation(
        name: "Test City",
        subtitle: "Test City",
        latitude: latitude,
        longitude: longitude,
        timeZoneIdentifier: "America/Los_Angeles",
        source: source
    )
}

struct UVMapEntryResolverTests {

    @Test func returnsCoordinateForRealLocation() {
        let location = makeSavedLocation(latitude: 37.7749, longitude: -122.4194)
        let coordinate = UVMapEntryResolver.coordinate(for: location, isUsingFallback: false)
        #expect(coordinate?.latitude == 37.7749)
        #expect(coordinate?.longitude == -122.4194)
    }

    @Test func returnsNilWhenLocationIsNil() {
        let coordinate = UVMapEntryResolver.coordinate(for: nil, isUsingFallback: true)
        #expect(coordinate == nil)
    }

    @Test func returnsNilWhenUsingFallback() {
        let location = makeSavedLocation(source: .fallback)
        let coordinate = UVMapEntryResolver.coordinate(for: location, isUsingFallback: true)
        #expect(coordinate == nil)
    }
}
