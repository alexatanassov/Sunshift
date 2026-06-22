import Foundation

// Mirrors CLAuthorizationStatus without importing CoreLocation outside the location layer.
// Populated by a future LocationPermissionObserver when real GPS access is wired up.
enum LocationPermissionStatus {
    case notDetermined
    case denied
    case restricted
    case authorizedWhenInUse
    case authorizedAlways
}
