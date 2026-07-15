import Testing
import Foundation
@testable import Sunshift

struct UVGridSnapshotTests {

    private func makeSnapshot(fetchedAt: Date) -> UVGridSnapshot {
        UVGridSnapshot(
            points: [UVDataPoint(latitude: 32.75, longitude: -117.15, uvIndex: 5, time: fetchedAt)],
            regionKey: "test-key",
            fetchedAt: fetchedAt
        )
    }

    @Test func freshUnder30Minutes() {
        let now = Date()
        let snapshot = makeSnapshot(fetchedAt: now.addingTimeInterval(-60 * 20))
        #expect(snapshot.freshness(asOf: now) == .fresh)
    }

    @Test func justUnder30MinutesIsStillFresh() {
        let now = Date()
        let snapshot = makeSnapshot(fetchedAt: now.addingTimeInterval(-(30 * 60 - 1)))
        #expect(snapshot.freshness(asOf: now) == .fresh)
    }

    @Test func staleButUsableBetween30MinutesAnd24Hours() {
        let now = Date()
        let snapshot = makeSnapshot(fetchedAt: now.addingTimeInterval(-60 * 60 * 2))
        #expect(snapshot.freshness(asOf: now) == .staleButUsable)
    }

    @Test func exactly30MinutesIsStaleButUsable() {
        let now = Date()
        let snapshot = makeSnapshot(fetchedAt: now.addingTimeInterval(-30 * 60))
        #expect(snapshot.freshness(asOf: now) == .staleButUsable)
    }

    @Test func justUnder24HoursIsStillStaleButUsable() {
        let now = Date()
        let snapshot = makeSnapshot(fetchedAt: now.addingTimeInterval(-(24 * 60 * 60 - 1)))
        #expect(snapshot.freshness(asOf: now) == .staleButUsable)
    }

    @Test func expiredAtOrAfter24Hours() {
        let now = Date()
        let snapshot = makeSnapshot(fetchedAt: now.addingTimeInterval(-24 * 60 * 60))
        #expect(snapshot.freshness(asOf: now) == .expired)
    }

    @Test func expiredWellPast24Hours() {
        let now = Date()
        let snapshot = makeSnapshot(fetchedAt: now.addingTimeInterval(-48 * 60 * 60))
        #expect(snapshot.freshness(asOf: now) == .expired)
    }
}
