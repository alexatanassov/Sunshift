import CoreLocation
import Foundation

// Testable interface. Concrete class is DeviceLocationService below.
protocol DeviceLocationServiceProtocol: AnyObject {
    var permissionStatus: LocationPermissionStatus { get }
    func requestWhenInUsePermission()
    func fetchCurrentLocation() async throws -> DeviceLocation
}

@Observable
final class DeviceLocationService: NSObject, DeviceLocationServiceProtocol {

    // MARK: - Published state

    private(set) var permissionStatus: LocationPermissionStatus = .notDetermined

    // MARK: - Private

    private let manager: CLLocationManager
    private var locationContinuation: CheckedContinuation<DeviceLocation, Error>?

    // MARK: - Init

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        permissionStatus = LocationPermissionStatus(clStatus: manager.authorizationStatus)
    }

    // MARK: - Protocol

    func requestWhenInUsePermission() {
        manager.requestWhenInUseAuthorization()
    }

    func fetchCurrentLocation() async throws -> DeviceLocation {
        guard locationContinuation == nil else {
            throw LocationError.fetchInProgress
        }
        switch permissionStatus {
        case .denied:
            throw LocationError.permissionDenied
        case .restricted:
            throw LocationError.permissionRestricted
        case .notDetermined:
            throw LocationError.locationUnavailable
        case .authorizedWhenInUse, .authorizedAlways:
            break
        }
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension DeviceLocationService: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = LocationPermissionStatus(clStatus: manager.authorizationStatus)
        Task { @MainActor in
            self.permissionStatus = status
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let raw = locations.last else { return }
        let result = DeviceLocation(
            latitude: raw.coordinate.latitude,
            longitude: raw.coordinate.longitude,
            accuracyMeters: raw.horizontalAccuracy,
            timestamp: raw.timestamp
        )
        Task { @MainActor in
            self.locationContinuation?.resume(returning: result)
            self.locationContinuation = nil
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            self.locationContinuation?.resume(throwing: LocationError.locationUnavailable)
            self.locationContinuation = nil
        }
    }
}

// MARK: - CLAuthorizationStatus bridging (private to this file)

private extension LocationPermissionStatus {
    init(clStatus: CLAuthorizationStatus) {
        switch clStatus {
        case .notDetermined:       self = .notDetermined
        case .denied:              self = .denied
        case .restricted:          self = .restricted
        case .authorizedWhenInUse: self = .authorizedWhenInUse
        case .authorizedAlways:    self = .authorizedAlways
        @unknown default:          self = .notDetermined
        }
    }
}
