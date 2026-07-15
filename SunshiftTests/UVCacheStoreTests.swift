import Testing
import Foundation
@testable import Sunshift

struct UVCacheStoreTests {

    // Each test gets its own throwaway directory so tests don't share cache state on disk.
    private func makeStore() -> (store: UVCacheStore, directory: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("UVCacheStoreTests-\(UUID().uuidString)", isDirectory: true)
        return (UVCacheStore(directoryURL: directory), directory)
    }

    private func makeSnapshot(regionKey: String = "uvgrid_test", fetchedAt: Date = Date()) -> UVGridSnapshot {
        UVGridSnapshot(
            points: [
                UVDataPoint(latitude: 32.75, longitude: -117.15, uvIndex: 4.2, time: fetchedAt),
                UVDataPoint(latitude: 32.80, longitude: -117.20, uvIndex: 5.1, time: fetchedAt),
            ],
            regionKey: regionKey,
            fetchedAt: fetchedAt
        )
    }

    // MARK: - Round-trip

    @Test func roundTripSavesAndLoadsSnapshot() throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let snapshot = makeSnapshot()
        store.save(snapshot)

        let loaded = store.load(regionKey: snapshot.regionKey)
        #expect(loaded == snapshot)
    }

    @Test func missingCacheEntryReturnsNil() {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(store.load(regionKey: "does-not-exist") == nil)
    }

    // MARK: - Corruption handling

    @Test func corruptedCacheFileReturnsNilInsteadOfCrashing() throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("uvgrid_bad.json")
        try Data("this is not valid json".utf8).write(to: fileURL)

        #expect(store.load(regionKey: "uvgrid_bad") == nil)
    }

    // MARK: - Region key stability

    @Test func stableCacheKeyForEquivalentRoundedRegions() {
        let centerA = UVForecastCoordinate(latitude: 32.7501, longitude: -117.1499)
        let centerB = UVForecastCoordinate(latitude: 32.7503, longitude: -117.1502)

        let keyA = UVCacheStore.regionKey(center: centerA, spanDegrees: 1.0)
        let keyB = UVCacheStore.regionKey(center: centerB, spanDegrees: 1.0)

        #expect(keyA == keyB)
    }

    @Test func differentCentersProduceDifferentKeys() {
        let centerA = UVForecastCoordinate(latitude: 32.75, longitude: -117.15)
        let centerB = UVForecastCoordinate(latitude: 40.71, longitude: -74.00)

        let keyA = UVCacheStore.regionKey(center: centerA, spanDegrees: 1.0)
        let keyB = UVCacheStore.regionKey(center: centerB, spanDegrees: 1.0)

        #expect(keyA != keyB)
    }

    @Test func differentSpansProduceDifferentKeysForSameCenter() {
        let center = UVForecastCoordinate(latitude: 32.75, longitude: -117.15)

        let keyA = UVCacheStore.regionKey(center: center, spanDegrees: 1.0)
        let keyB = UVCacheStore.regionKey(center: center, spanDegrees: 2.0)

        #expect(keyA != keyB)
    }
}
