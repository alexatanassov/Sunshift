import Testing
import Foundation
import Observation
@testable import Sunshift

// MARK: - Mocks

// @Observable so withObservationTracking in LocationViewModel can watch permissionStatus changes.
@MainActor
@Observable
final class MockDeviceLocationService: DeviceLocationServiceProtocol {
    var permissionStatus: LocationPermissionStatus = .notDetermined
    var requestPermissionCallCount = 0
    var locationToReturn: DeviceLocation?
    var errorToThrow: Error?

    func requestWhenInUsePermission() {
        requestPermissionCallCount += 1
    }

    func fetchCurrentLocation() async throws -> DeviceLocation {
        if let error = errorToThrow { throw error }
        return locationToReturn ?? DeviceLocation(
            latitude: 34.0, longitude: -118.0, accuracyMeters: 10, timestamp: Date()
        )
    }
}

@MainActor
final class MockGeocodingService: LocationGeocodingServiceProtocol {
    var geocodedResult: GeocodedLocation?
    var errorToThrow: Error?

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> GeocodedLocation {
        if let error = errorToThrow { throw error }
        return geocodedResult ?? GeocodedLocation(
            latitude: latitude, longitude: longitude,
            city: "Test City", state: nil, country: "Testland",
            isoCountryCode: "TT", timeZoneIdentifier: "UTC"
        )
    }

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

// MARK: - Test helpers

// Creates a LocationViewModel with isolated UserDefaults and injectable mock dependencies.
// When deviceService is nil, a fresh MockDeviceLocationService is created with the given permissionStatus.
@MainActor
private func makeVM(
    permissionStatus: LocationPermissionStatus = .notDetermined,
    deviceService: MockDeviceLocationService? = nil,
    geocodingService: MockGeocodingService? = nil,
    subscriptionTier: SubscriptionTier = .free
) -> (vm: LocationViewModel, store: LocationStore, deviceService: MockDeviceLocationService) {
    let device: MockDeviceLocationService
    if let provided = deviceService {
        device = provided
    } else {
        device = MockDeviceLocationService()
        device.permissionStatus = permissionStatus
    }
    let geocoder = geocodingService ?? MockGeocodingService()
    let sub = SubscriptionService()
    sub.tier = subscriptionTier
    let defaults = UserDefaults(suiteName: "LocationViewModelTests-\(UUID().uuidString)")!
    let store = LocationStore(defaults: defaults)
    let vm = LocationViewModel(
        store: store,
        deviceLocationService: device,
        geocodingService: geocoder,
        subscriptionService: sub
    )
    return (vm, store, device)
}

// MARK: - Tests

@MainActor
struct LocationViewModelTests {

    // MARK: Initial state

    @Test func loadInitialLocation_withEmptyStore_usesDevFallback() {
        let (vm, _, _) = makeVM()
        vm.loadInitialLocation()
        #expect(vm.isUsingFallback)
        #expect(vm.resolvedLocation.id == SavedLocation.devFallback.id)
        #expect(vm.activeLocation == nil)
    }

    // MARK: setActiveLocation

    @Test func setActiveLocation_updatesActiveLocation() {
        let (vm, store, _) = makeVM()
        let location = SavedLocation(
            name: "Paris", subtitle: "Paris, France",
            latitude: 48.8566, longitude: 2.3522,
            timeZoneIdentifier: "Europe/Paris"
        )
        store.add(location)
        vm.setActiveLocation(location)
        #expect(vm.activeLocation?.id == location.id)
        #expect(!vm.isUsingFallback)
    }

    // MARK: removeSavedLocation

    @Test func removeSavedLocation_removesFromListAndClearsActive() {
        let (vm, store, _) = makeVM()
        let location = SavedLocation(
            name: "London", subtitle: "London, UK",
            latitude: 51.5074, longitude: -0.1278,
            timeZoneIdentifier: "Europe/London"
        )
        store.add(location)
        vm.setActiveLocation(location)
        #expect(vm.savedLocations.count == 1)

        vm.removeSavedLocation(location)
        #expect(vm.savedLocations.isEmpty)
        #expect(vm.activeLocation == nil)
    }

    // MARK: saveManualLocation

    @Test func saveManualLocation_underFreeTierLimit_savesAndActivates() {
        let (vm, _, _) = makeVM(subscriptionTier: .free)
        let location = SavedLocation(
            name: "Tokyo", subtitle: "Tokyo, Japan",
            latitude: 35.6762, longitude: 139.6503,
            timeZoneIdentifier: "Asia/Tokyo",
            source: .manual
        )
        vm.saveManualLocation(location)
        #expect(vm.userFacingError == nil)
        #expect(vm.savedLocations.count == 1)
        #expect(vm.activeLocation?.id == location.id)
    }

    @Test func saveManualLocation_atFreeTierLimit_setsErrorAndDoesNotAdd() {
        let (vm, store, _) = makeVM(subscriptionTier: .free)
        let existing = SavedLocation(
            name: "Berlin", subtitle: "Berlin, Germany",
            latitude: 52.52, longitude: 13.405,
            timeZoneIdentifier: "Europe/Berlin",
            source: .manual
        )
        store.add(existing)
        vm.loadInitialLocation() // sync store state into vm

        let another = SavedLocation(
            name: "Sydney", subtitle: "Sydney, Australia",
            latitude: -33.8688, longitude: 151.2093,
            timeZoneIdentifier: "Australia/Sydney",
            source: .manual
        )
        vm.saveManualLocation(another)
        #expect(vm.userFacingError != nil)
        #expect(vm.savedLocations.count == 1)
    }

    @Test func saveManualLocation_withPlusTier_allowsMultiple() {
        let (vm, store, _) = makeVM(subscriptionTier: .plus)
        let existing = SavedLocation(
            name: "Berlin", subtitle: "Berlin, Germany",
            latitude: 52.52, longitude: 13.405,
            timeZoneIdentifier: "Europe/Berlin",
            source: .manual
        )
        store.add(existing)
        vm.loadInitialLocation()

        let another = SavedLocation(
            name: "Sydney", subtitle: "Sydney, Australia",
            latitude: -33.8688, longitude: 151.2093,
            timeZoneIdentifier: "Australia/Sydney",
            source: .manual
        )
        vm.saveManualLocation(another)
        #expect(vm.userFacingError == nil)
        #expect(vm.savedLocations.count == 2)
    }

    // MARK: requestLocationPermissionIfNeeded

    @Test func requestLocationPermissionIfNeeded_whenNotDetermined_requestsPermission() {
        let (vm, _, device) = makeVM(permissionStatus: .notDetermined)
        vm.requestLocationPermissionIfNeeded()
        #expect(device.requestPermissionCallCount == 1)
    }

    @Test func requestLocationPermissionIfNeeded_whenAlreadyAuthorized_doesNotRequest() {
        let (vm, _, device) = makeVM(permissionStatus: .authorizedWhenInUse)
        vm.requestLocationPermissionIfNeeded()
        #expect(device.requestPermissionCallCount == 0)
    }

    @Test func requestLocationPermissionIfNeeded_whenDenied_doesNotRequest() {
        let (vm, _, device) = makeVM(permissionStatus: .denied)
        vm.requestLocationPermissionIfNeeded()
        #expect(device.requestPermissionCallCount == 0)
    }

    // MARK: useCurrentLocation

    @Test func useCurrentLocation_withDeniedPermission_setsError() async {
        let (vm, _, _) = makeVM(permissionStatus: .denied)
        await vm.useCurrentLocation()
        #expect(vm.userFacingError != nil)
        #expect(vm.isLoading == false)
    }

    @Test func useCurrentLocation_withNotDetermined_requestsPermissionAndDefersLoad() async {
        let (vm, _, device) = makeVM(permissionStatus: .notDetermined)
        await vm.useCurrentLocation()
        #expect(device.requestPermissionCallCount == 1)
        #expect(vm.activeLocation == nil) // fetch deferred until permission granted
    }

    @Test func useCurrentLocation_withSuccessfulGeocode_activatesGeocodedLocation() async {
        let device = MockDeviceLocationService()
        device.permissionStatus = .authorizedWhenInUse
        device.locationToReturn = DeviceLocation(
            latitude: 34.0522, longitude: -118.2437,
            accuracyMeters: 5, timestamp: Date()
        )
        let geocoder = MockGeocodingService()
        geocoder.geocodedResult = GeocodedLocation(
            latitude: 34.0522, longitude: -118.2437,
            city: "Los Angeles", state: "CA", country: "United States",
            isoCountryCode: "US", timeZoneIdentifier: "America/Los_Angeles"
        )

        let (vm, _, _) = makeVM(deviceService: device, geocodingService: geocoder)
        await vm.useCurrentLocation()

        #expect(vm.userFacingError == nil)
        #expect(vm.activeLocation?.name == "Los Angeles")
        #expect(vm.activeLocation?.source == .current)
        #expect(vm.activeLocation?.isCurrentLocation == true)
        #expect(!vm.isUsingFallback)
    }

    @Test func useCurrentLocation_whenGeocodingFails_savesWithGenericName() async {
        let device = MockDeviceLocationService()
        device.permissionStatus = .authorizedWhenInUse
        device.locationToReturn = DeviceLocation(
            latitude: 34.0, longitude: -118.0, accuracyMeters: 5, timestamp: Date()
        )
        let geocoder = MockGeocodingService()
        geocoder.errorToThrow = GeocodingError.noResultsFound

        let (vm, _, _) = makeVM(deviceService: device, geocodingService: geocoder)
        await vm.useCurrentLocation()

        #expect(vm.userFacingError == nil)
        #expect(vm.activeLocation?.name == "Current Location")
        #expect(vm.activeLocation?.isCurrentLocation == true)
    }

    @Test func useCurrentLocation_replacesExistingCurrentLocation() async {
        let device = MockDeviceLocationService()
        device.permissionStatus = .authorizedWhenInUse
        device.locationToReturn = DeviceLocation(
            latitude: 37.7749, longitude: -122.4194,
            accuracyMeters: 10, timestamp: Date()
        )

        let (vm, store, _) = makeVM(deviceService: device)
        let stale = SavedLocation(
            name: "Old Location", subtitle: "",
            latitude: 0, longitude: 0,
            timeZoneIdentifier: "UTC",
            source: .current, isCurrentLocation: true
        )
        store.add(stale)
        vm.loadInitialLocation()
        #expect(vm.savedLocations.count == 1)

        await vm.useCurrentLocation()

        let currentEntries = vm.savedLocations.filter { $0.isCurrentLocation }
        #expect(currentEntries.count == 1)
        #expect(currentEntries.first?.name != "Old Location")
    }

    // MARK: refreshCurrentLocation

    @Test func refreshCurrentLocation_withDeniedPermission_setsError() async {
        let (vm, _, _) = makeVM(permissionStatus: .denied)
        await vm.refreshCurrentLocation()
        #expect(vm.userFacingError != nil)
    }

    @Test func refreshCurrentLocation_withAuthorizedPermission_updatesLocation() async {
        let device = MockDeviceLocationService()
        device.permissionStatus = .authorizedWhenInUse
        device.locationToReturn = DeviceLocation(
            latitude: 48.8566, longitude: 2.3522,
            accuracyMeters: 8, timestamp: Date()
        )
        let geocoder = MockGeocodingService()
        geocoder.geocodedResult = GeocodedLocation(
            latitude: 48.8566, longitude: 2.3522,
            city: "Paris", state: nil, country: "France",
            isoCountryCode: "FR", timeZoneIdentifier: "Europe/Paris"
        )

        let (vm, _, _) = makeVM(deviceService: device, geocodingService: geocoder)
        await vm.refreshCurrentLocation()

        #expect(vm.userFacingError == nil)
        #expect(vm.activeLocation?.name == "Paris")
    }

    // MARK: canAddManualLocation

    @Test func canAddManualLocation_freeTierWithNoLocations_isTrue() {
        let (vm, _, _) = makeVM(subscriptionTier: .free)
        #expect(vm.canAddManualLocation)
    }

    @Test func canAddManualLocation_freeTierAtLimit_isFalse() {
        let (vm, store, _) = makeVM(subscriptionTier: .free)
        let location = SavedLocation(
            name: "Home", subtitle: "",
            latitude: 37.0, longitude: -122.0,
            timeZoneIdentifier: "America/Los_Angeles",
            source: .manual
        )
        store.add(location)
        #expect(!vm.canAddManualLocation)
    }

    @Test func canAddManualLocation_plusTierAlwaysTrue() {
        let (vm, store, _) = makeVM(subscriptionTier: .plus)
        for i in 0..<5 {
            store.add(SavedLocation(
                name: "Location \(i)", subtitle: "",
                latitude: Double(i), longitude: Double(i),
                timeZoneIdentifier: "UTC",
                source: .manual
            ))
        }
        #expect(vm.canAddManualLocation)
    }
}
