import Foundation
import Observation

// Coordinates location permission, device GPS, geocoding, and persistence.
// Inject into the environment from SunshiftApp; read from any view via @Environment(LocationViewModel.self).
@Observable
final class LocationViewModel {

    // MARK: - State

    private(set) var activeLocation: SavedLocation?
    private(set) var savedLocations: [SavedLocation] = []
    private(set) var permissionStatus: LocationPermissionStatus = .notDetermined
    private(set) var isLoading = false
    var userFacingError: String?

    // MARK: - Dependencies

    private let store: LocationStore
    private let deviceLocationService: any DeviceLocationServiceProtocol
    private let geocodingService: any LocationGeocodingServiceProtocol
    private let subscriptionService: SubscriptionService

    // True when the user triggered useCurrentLocation() while permission was still undetermined.
    // Cleared and acted on once the permission response arrives.
    private var pendingCurrentLocationFetch = false

    // MARK: - Init

    init(
        store: LocationStore = LocationStore(),
        deviceLocationService: any DeviceLocationServiceProtocol = DeviceLocationService(),
        geocodingService: any LocationGeocodingServiceProtocol = LocationGeocodingService(),
        subscriptionService: SubscriptionService
    ) {
        self.store = store
        self.deviceLocationService = deviceLocationService
        self.geocodingService = geocodingService
        self.subscriptionService = subscriptionService
        self.permissionStatus = deviceLocationService.permissionStatus
        syncFromStore()
        observePermissionStatus()
    }

    // MARK: - Computed

    /// Location used for solar calculations. San Diego fallback when nothing has been set.
    var resolvedLocation: SavedLocation {
        activeLocation ?? .devFallback
    }

    /// True when the resolved location is the dev fallback rather than a real user location.
    var isUsingFallback: Bool {
        activeLocation == nil || activeLocation?.source == .fallback
    }

    /// Whether the user may save an additional manual/home location under their current plan.
    var canAddManualLocation: Bool {
        store.canAddSavedLocation(tier: subscriptionService.tier)
    }

    // MARK: - Actions

    /// Call once on app launch. Ensures resolvedLocation is ready; uses the fallback if no
    /// location has been saved yet.
    @MainActor
    func loadInitialLocation() {
        syncFromStore()
    }

    /// Asks for location permission only when the status is still undetermined.
    @MainActor
    func requestLocationPermissionIfNeeded() {
        guard permissionStatus == .notDetermined else { return }
        deviceLocationService.requestWhenInUsePermission()
    }

    /// Requests permission if needed, then fetches and activates the device's current location.
    /// When permission is still undetermined, the fetch is deferred until the user responds to
    /// the system prompt -- call this method again after permission is granted if needed.
    @MainActor
    func useCurrentLocation() async {
        if permissionStatus == .notDetermined {
            pendingCurrentLocationFetch = true
            deviceLocationService.requestWhenInUsePermission()
            return
        }
        guard isAuthorized else {
            pendingCurrentLocationFetch = false
            userFacingError = deniedPermissionMessage
            return
        }
        pendingCurrentLocationFetch = false
        await fetchAndApplyCurrentLocation()
    }

    /// Re-fetches the current location. Requires permission to already be granted.
    @MainActor
    func refreshCurrentLocation() async {
        guard isAuthorized else {
            userFacingError = "Location access is required to refresh your current position."
            return
        }
        await fetchAndApplyCurrentLocation()
    }

    /// Makes the given location active for solar calculations.
    @MainActor
    func setActiveLocation(_ location: SavedLocation) {
        store.setActiveLocation(location)
        syncFromStore()
    }

    /// Saves a manual/home location and activates it.
    /// Enforces the free-tier limit of one saved non-current location.
    @MainActor
    func saveManualLocation(_ location: SavedLocation) {
        guard canAddManualLocation else {
            userFacingError = "You can save one home location on the free plan. Upgrade to Helio Plus to save more."
            return
        }
        store.add(location)
        store.setActiveLocation(location)
        syncFromStore()
    }

    /// Removes a saved location. If it was the active location, clears the active selection.
    @MainActor
    func removeSavedLocation(_ location: SavedLocation) {
        store.remove(id: location.id)
        syncFromStore()
    }

    /// Resolves a display name and timezone for a coordinate picked on the map.
    /// Returns nil if geocoding fails; callers should leave their fields as-is in that case.
    @MainActor
    func reverseGeocodedLocation(latitude: Double, longitude: Double) async -> GeocodedLocation? {
        try? await geocodingService.reverseGeocode(latitude: latitude, longitude: longitude)
    }

    // MARK: - Private helpers

    private var isAuthorized: Bool {
        permissionStatus == .authorizedWhenInUse || permissionStatus == .authorizedAlways
    }

    private var deniedPermissionMessage: String {
        switch permissionStatus {
        case .denied:
            return "Location access has been denied. Enable it in Settings to use your current location."
        case .restricted:
            return "Location access is restricted on this device."
        default:
            return "Location access is not available."
        }
    }

    @MainActor
    private func fetchAndApplyCurrentLocation() async {
        isLoading = true
        userFacingError = nil
        defer { isLoading = false }

        let deviceLocation: DeviceLocation
        do {
            deviceLocation = try await deviceLocationService.fetchCurrentLocation()
        } catch {
            userFacingError = locationErrorMessage(for: error)
            return
        }

        // Replace any previous current-location entry so there is never more than one.
        if let previous = store.savedLocations.first(where: { $0.isCurrentLocation }) {
            store.remove(id: previous.id)
        }

        let saved: SavedLocation
        do {
            let geocoded = try await geocodingService.reverseGeocode(
                latitude: deviceLocation.latitude,
                longitude: deviceLocation.longitude
            )
            saved = geocodingService.makeSavedLocation(from: geocoded, source: .current)
        } catch {
            // Geocoding failed -- still activate the coordinates with a generic name.
            saved = SavedLocation(
                name: "Current Location",
                subtitle: "Current Location",
                latitude: deviceLocation.latitude,
                longitude: deviceLocation.longitude,
                timeZoneIdentifier: TimeZone.current.identifier,
                source: .current,
                isCurrentLocation: true
            )
        }

        store.add(saved)
        store.setActiveLocation(saved)
        syncFromStore()
    }

    @MainActor
    private func syncFromStore() {
        savedLocations = store.savedLocations
        activeLocation = store.activeLocation
    }

    // Re-registers observation after each change so permission updates always propagate.
    private func observePermissionStatus() {
        withObservationTracking {
            _ = deviceLocationService.permissionStatus
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let newStatus = self.deviceLocationService.permissionStatus
                self.permissionStatus = newStatus
                if self.pendingCurrentLocationFetch {
                    if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                        self.pendingCurrentLocationFetch = false
                        await self.fetchAndApplyCurrentLocation()
                    } else if newStatus == .denied || newStatus == .restricted {
                        self.pendingCurrentLocationFetch = false
                        self.userFacingError = self.deniedPermissionMessage
                    }
                }
                self.observePermissionStatus()
            }
        }
    }

    private func locationErrorMessage(for error: Error) -> String {
        switch error {
        case LocationError.permissionDenied:
            return "Location access has been denied. Enable it in Settings to use your current location."
        case LocationError.permissionRestricted:
            return "Location access is restricted on this device."
        case LocationError.locationUnavailable:
            return "Your current location could not be determined. Try again in a moment."
        case LocationError.fetchInProgress:
            return "A location request is already in progress."
        default:
            return "Something went wrong while getting your location. Try again."
        }
    }
}
