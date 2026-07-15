import Testing
import Foundation
@testable import Sunshift

@MainActor
struct UVMapViewModelTests {

    private let center = UVForecastCoordinate(latitude: 32.75, longitude: -117.15)

    // MARK: - Fixtures

    private final class MockUVForecastService: UVForecastServiceProtocol {
        var errorToThrow: Error?
        var uvIndexToReturn: Double = 5.0
        private(set) var requestedCoordinates: [[UVForecastCoordinate]] = []

        var callCount: Int { requestedCoordinates.count }

        func fetchCurrentUVIndex(for coordinates: [UVForecastCoordinate]) async throws -> [UVDataPoint] {
            requestedCoordinates.append(coordinates)
            if let errorToThrow { throw errorToThrow }
            return coordinates.map {
                UVDataPoint(latitude: $0.latitude, longitude: $0.longitude, uvIndex: uvIndexToReturn, time: Date())
            }
        }
    }

    // Each test gets its own throwaway cache directory so tests don't share state on disk.
    private func makeCacheStore() -> (store: UVCacheStore, directory: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("UVMapViewModelTests-\(UUID().uuidString)", isDirectory: true)
        return (UVCacheStore(directoryURL: directory), directory)
    }

    private func makeSnapshot(regionKey: String, fetchedAt: Date) -> UVGridSnapshot {
        UVGridSnapshot(
            points: [UVDataPoint(latitude: 32.75, longitude: -117.15, uvIndex: 3, time: fetchedAt)],
            regionKey: regionKey,
            fetchedAt: fetchedAt
        )
    }

    // MARK: - Fresh cache

    @Test func freshCacheReturnsCachedDataWithoutCallingService() async {
        let (cacheStore, directory) = makeCacheStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let now = Date()
        let regionKey = UVCacheStore.regionKey(center: center, spanDegrees: UVMapGridSampler.defaultSpanDegrees)
        let snapshot = makeSnapshot(regionKey: regionKey, fetchedAt: now.addingTimeInterval(-60 * 5))
        cacheStore.save(snapshot)

        let service = MockUVForecastService()
        let viewModel = UVMapViewModel(service: service, cacheStore: cacheStore, now: { now })

        await viewModel.load(center: center)

        #expect(viewModel.state == .loaded(snapshot: snapshot, isStale: false))
        #expect(service.callCount == 0)
    }

    // MARK: - Missing cache

    @Test func missingCacheFetchesServiceAndSavesSnapshot() async {
        let (cacheStore, directory) = makeCacheStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let now = Date()
        let service = MockUVForecastService()
        let viewModel = UVMapViewModel(service: service, cacheStore: cacheStore, now: { now })

        await viewModel.load(center: center)

        #expect(service.callCount == 1)

        guard case .loaded(let snapshot, let isStale) = viewModel.state else {
            Issue.record("Expected .loaded state, got \(viewModel.state)")
            return
        }
        #expect(isStale == false)
        #expect(snapshot.fetchedAt == now)

        let regionKey = UVCacheStore.regionKey(center: center, spanDegrees: UVMapGridSampler.defaultSpanDegrees)
        #expect(cacheStore.load(regionKey: regionKey) == snapshot)
    }

    // MARK: - Expired cache

    @Test func expiredCacheFetchesServiceAndReplacesCache() async {
        let (cacheStore, directory) = makeCacheStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let now = Date()
        let regionKey = UVCacheStore.regionKey(center: center, spanDegrees: UVMapGridSampler.defaultSpanDegrees)
        let expired = makeSnapshot(regionKey: regionKey, fetchedAt: now.addingTimeInterval(-60 * 60 * 25))
        cacheStore.save(expired)

        let service = MockUVForecastService()
        service.uvIndexToReturn = 7.0
        let viewModel = UVMapViewModel(service: service, cacheStore: cacheStore, now: { now })

        await viewModel.load(center: center)

        #expect(service.callCount == 1)

        guard case .loaded(let snapshot, let isStale) = viewModel.state else {
            Issue.record("Expected .loaded state, got \(viewModel.state)")
            return
        }
        #expect(isStale == false)
        #expect(snapshot != expired)
        #expect(cacheStore.load(regionKey: regionKey) == snapshot)
    }

    // MARK: - Stale but usable cache

    @Test func staleButUsableCacheIsSurfacedWithoutCallingService() async {
        let (cacheStore, directory) = makeCacheStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let now = Date()
        let regionKey = UVCacheStore.regionKey(center: center, spanDegrees: UVMapGridSampler.defaultSpanDegrees)
        let stale = makeSnapshot(regionKey: regionKey, fetchedAt: now.addingTimeInterval(-60 * 60 * 2))
        cacheStore.save(stale)

        let service = MockUVForecastService()
        let viewModel = UVMapViewModel(service: service, cacheStore: cacheStore, now: { now })

        await viewModel.load(center: center)

        #expect(viewModel.state == .loaded(snapshot: stale, isStale: true))
        #expect(service.callCount == 0)
    }

    @Test func refreshOnStaleCacheFetchesServiceAndReplacesCache() async {
        let (cacheStore, directory) = makeCacheStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let now = Date()
        let regionKey = UVCacheStore.regionKey(center: center, spanDegrees: UVMapGridSampler.defaultSpanDegrees)
        let stale = makeSnapshot(regionKey: regionKey, fetchedAt: now.addingTimeInterval(-60 * 60 * 2))
        cacheStore.save(stale)

        let service = MockUVForecastService()
        let viewModel = UVMapViewModel(service: service, cacheStore: cacheStore, now: { now })

        await viewModel.refresh(center: center)

        #expect(service.callCount == 1)
        guard case .loaded(let snapshot, let isStale) = viewModel.state else {
            Issue.record("Expected .loaded state, got \(viewModel.state)")
            return
        }
        #expect(isStale == false)
        #expect(snapshot != stale)
        #expect(cacheStore.load(regionKey: regionKey) == snapshot)
    }

    // MARK: - Service failure

    @Test func serviceFailureWithCachedDataReturnsUsableCachedState() async {
        let (cacheStore, directory) = makeCacheStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let now = Date()
        let regionKey = UVCacheStore.regionKey(center: center, spanDegrees: UVMapGridSampler.defaultSpanDegrees)
        // Expired, so load() attempts a network fetch rather than returning the cache directly.
        let expired = makeSnapshot(regionKey: regionKey, fetchedAt: now.addingTimeInterval(-60 * 60 * 25))
        cacheStore.save(expired)

        let service = MockUVForecastService()
        service.errorToThrow = UVForecastError.missingUVData
        let viewModel = UVMapViewModel(service: service, cacheStore: cacheStore, now: { now })

        await viewModel.load(center: center)

        #expect(viewModel.state == .loaded(snapshot: expired, isStale: true))
    }

    @Test func serviceFailureWithoutCacheReturnsFailedState() async {
        let (cacheStore, directory) = makeCacheStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let service = MockUVForecastService()
        service.errorToThrow = UVForecastError.missingUVData
        let viewModel = UVMapViewModel(service: service, cacheStore: cacheStore, now: { Date() })

        await viewModel.load(center: center)

        guard case .failed = viewModel.state else {
            Issue.record("Expected .failed state, got \(viewModel.state)")
            return
        }
    }

    // MARK: - Grid size

    @Test func generatedServiceRequestUsesExpected5x5GridCount() async {
        let (cacheStore, directory) = makeCacheStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let service = MockUVForecastService()
        let viewModel = UVMapViewModel(service: service, cacheStore: cacheStore, now: { Date() })

        await viewModel.load(center: center)

        #expect(service.requestedCoordinates.first?.count == 25)
    }

    // MARK: - Region too large

    @Test func regionTooLargeIsReportedWithoutCallingService() async {
        let (cacheStore, directory) = makeCacheStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let service = MockUVForecastService()
        let viewModel = UVMapViewModel(service: service, cacheStore: cacheStore, now: { Date() })

        await viewModel.load(center: center, spanDegrees: UVMapGridSampler.maxSpanDegrees + 1)

        #expect(viewModel.state == .regionTooLarge)
        #expect(service.callCount == 0)
    }
}
