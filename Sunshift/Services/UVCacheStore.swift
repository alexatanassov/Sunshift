import Foundation

// Persists recently fetched UV Map grid snapshots to disk as JSON, so the map can show
// prior results without immediately refetching. Pure persistence logic only: no
// networking, no SwiftUI, no MapKit.
final class UVCacheStore {

    private let directoryURL: URL
    private let fileManager: FileManager

    // Pass `directoryURL` to redirect storage (e.g. a temporary directory in tests).
    // Defaults to a subdirectory of the platform Caches directory.
    init(directoryURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.directoryURL = caches.appendingPathComponent("UVMapCache", isDirectory: true)
        }
    }

    // MARK: - Region key

    // A stable key for a grid region, based on its rounded center coordinate and span.
    // Rounding to 2 decimal places (~1.1km) means nearby centers that describe the same
    // effective region (e.g. from minor GPS jitter) resolve to the same cache entry.
    static func regionKey(center: UVForecastCoordinate, spanDegrees: Double) -> String {
        let latitude = roundedComponent(center.latitude)
        let longitude = roundedComponent(center.longitude)
        let span = roundedComponent(spanDegrees)
        return "uvgrid_\(latitude)_\(longitude)_\(span)"
    }

    private static func roundedComponent(_ value: Double) -> String {
        String(format: "%.2f", (value * 100).rounded() / 100)
    }

    // MARK: - Save / Load

    func save(_ snapshot: UVGridSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? ensureDirectoryExists()
        try? data.write(to: fileURL(for: snapshot.regionKey), options: .atomic)
    }

    // Returns nil on a cache miss or on corrupted/unreadable data. Never throws or crashes.
    func load(regionKey: String) -> UVGridSnapshot? {
        guard let data = try? Data(contentsOf: fileURL(for: regionKey)) else { return nil }
        return try? JSONDecoder().decode(UVGridSnapshot.self, from: data)
    }

    // MARK: - Private

    private func fileURL(for regionKey: String) -> URL {
        directoryURL.appendingPathComponent("\(regionKey).json")
    }

    private func ensureDirectoryExists() throws {
        guard !fileManager.fileExists(atPath: directoryURL.path) else { return }
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}
