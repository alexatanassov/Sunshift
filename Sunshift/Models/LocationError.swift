import Foundation

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case permissionRestricted
    case locationUnavailable
    case fetchInProgress

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access has been denied. Enable it in Settings to use this feature."
        case .permissionRestricted:
            return "Location access is restricted on this device."
        case .locationUnavailable:
            return "Your current location could not be determined."
        case .fetchInProgress:
            return "A location request is already in progress."
        }
    }
}
