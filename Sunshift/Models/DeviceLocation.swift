import Foundation

// App-level result of a one-shot GPS fetch. Decoupled from CLLocation.
struct DeviceLocation {
    let latitude: Double
    let longitude: Double
    let accuracyMeters: Double
    let timestamp: Date
}
