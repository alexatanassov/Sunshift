import Foundation
import Observation

// Coordinates the UV Map's data: checks the cache first, falls back to a network fetch via
// UVForecastServiceProtocol, and keeps showing cached data if a fetch fails. No map
// rendering or UI copy beyond simple status text lives here.
@Observable
final class UVMapViewModel {

    // MARK: - State

    enum State: Equatable {
        case idle
        case loading
        // `isStale` is true when the snapshot did not come from a fresh network fetch just now
        // (read from a stale-but-usable cache entry, or kept on screen after a failed refresh).
        case loaded(snapshot: UVGridSnapshot, isStale: Bool)
        case failed(message: String)
        case regionTooLarge
    }

    private(set) var state: State = .idle

    // MARK: - Dependencies

    private let service: any UVForecastServiceProtocol
    private let cacheStore: UVCacheStore
    private let now: () -> Date

    init(
        service: any UVForecastServiceProtocol = OpenMeteoUVService(),
        cacheStore: UVCacheStore = UVCacheStore(),
        now: @escaping () -> Date = Date.init
    ) {
        self.service = service
        self.cacheStore = cacheStore
        self.now = now
    }

    // MARK: - Loading

    // Checks the cache first. Fresh cache is shown as-is with no network call. Stale-but-usable
    // cache is shown immediately (call `refresh` to update it in the background). Missing or
    // expired cache triggers a network fetch.
    @MainActor
    func load(center: UVForecastCoordinate, spanDegrees: Double = UVMapGridSampler.defaultSpanDegrees) async {
        guard spanDegrees <= UVMapGridSampler.maxSpanDegrees else {
            state = .regionTooLarge
            return
        }

        let regionKey = UVCacheStore.regionKey(center: center, spanDegrees: spanDegrees)
        let cached = cacheStore.load(regionKey: regionKey)

        if let cached {
            switch cached.freshness(asOf: now()) {
            case .fresh:
                state = .loaded(snapshot: cached, isStale: false)
                return
            case .staleButUsable:
                state = .loaded(snapshot: cached, isStale: true)
                return
            case .expired:
                break
            }
        }

        await fetchAndStore(center: center, spanDegrees: spanDegrees, regionKey: regionKey, fallback: cached)
    }

    // Forces a network refresh regardless of cache freshness. Useful for a pull-to-refresh
    // action on data that's already being shown as stale-but-usable.
    @MainActor
    func refresh(center: UVForecastCoordinate, spanDegrees: Double = UVMapGridSampler.defaultSpanDegrees) async {
        guard spanDegrees <= UVMapGridSampler.maxSpanDegrees else {
            state = .regionTooLarge
            return
        }

        let regionKey = UVCacheStore.regionKey(center: center, spanDegrees: spanDegrees)
        let cached = cacheStore.load(regionKey: regionKey)
        await fetchAndStore(center: center, spanDegrees: spanDegrees, regionKey: regionKey, fallback: cached)
    }

    // MARK: - Private

    @MainActor
    private func fetchAndStore(
        center: UVForecastCoordinate,
        spanDegrees: Double,
        regionKey: String,
        fallback: UVGridSnapshot?
    ) async {
        state = .loading

        let coordinates = UVMapGridSampler.generateGrid(center: center, spanDegrees: spanDegrees)

        do {
            let points = try await service.fetchCurrentUVIndex(for: coordinates)
            let snapshot = UVGridSnapshot(points: points, regionKey: regionKey, fetchedAt: now())
            cacheStore.save(snapshot)
            state = .loaded(snapshot: snapshot, isStale: false)
        } catch {
            // Any existing cache, even an expired one, is still more useful than an error screen.
            if let fallback {
                state = .loaded(snapshot: fallback, isStale: true)
            } else {
                state = .failed(message: "Could not load UV data. Try again in a moment.")
            }
        }
    }
}
