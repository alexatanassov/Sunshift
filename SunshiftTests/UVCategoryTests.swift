import Testing
import Foundation
@testable import Sunshift

// MARK: - UVCategory threshold boundaries

struct UVCategoryTests {

    // MARK: Low

    @Test func zeroIsLow() {
        #expect(UVCategory(uvIndex: 0) == .low)
    }

    @Test func negativeValueIsTreatedAsLow() {
        #expect(UVCategory(uvIndex: -1) == .low)
    }

    @Test func justBelowModerateBoundaryIsLow() {
        #expect(UVCategory(uvIndex: 2.9) == .low)
    }

    // MARK: Moderate

    @Test func moderateLowerBoundaryIsModerate() {
        #expect(UVCategory(uvIndex: 3) == .moderate)
    }

    @Test func justBelowHighBoundaryIsModerate() {
        #expect(UVCategory(uvIndex: 5.9) == .moderate)
    }

    // MARK: High

    @Test func highLowerBoundaryIsHigh() {
        #expect(UVCategory(uvIndex: 6) == .high)
    }

    @Test func justBelowVeryHighBoundaryIsHigh() {
        #expect(UVCategory(uvIndex: 7.9) == .high)
    }

    // MARK: Very High

    @Test func veryHighLowerBoundaryIsVeryHigh() {
        #expect(UVCategory(uvIndex: 8) == .veryHigh)
    }

    @Test func justBelowExtremeBoundaryIsVeryHigh() {
        #expect(UVCategory(uvIndex: 10.9) == .veryHigh)
    }

    // MARK: Extreme

    @Test func extremeLowerBoundaryIsExtreme() {
        #expect(UVCategory(uvIndex: 11) == .extreme)
    }

    @Test func veryLargeValueIsExtreme() {
        #expect(UVCategory(uvIndex: 20) == .extreme)
    }

    // MARK: displayName

    @Test func displayNamesMatchExpectedLabels() {
        #expect(UVCategory.low.displayName == "Low")
        #expect(UVCategory.moderate.displayName == "Moderate")
        #expect(UVCategory.high.displayName == "High")
        #expect(UVCategory.veryHigh.displayName == "Very High")
        #expect(UVCategory.extreme.displayName == "Extreme")
    }

    // MARK: allCases

    @Test func allCasesHasFiveBands() {
        #expect(UVCategory.allCases.count == 5)
    }
}

// MARK: - UVDataPoint

struct UVDataPointTests {

    @Test func categoryIsDerivedFromUVIndex() {
        let point = UVDataPoint(latitude: 32.7157, longitude: -117.1611, uvIndex: 6.3, time: Date())
        #expect(point.category == .high)
    }

    @Test func equatableComparesAllFields() {
        let time = Date()
        let id = UUID()
        let a = UVDataPoint(id: id, latitude: 1, longitude: 2, uvIndex: 3, time: time)
        let b = UVDataPoint(id: id, latitude: 1, longitude: 2, uvIndex: 3, time: time)
        #expect(a == b)
    }

    @Test func codableRoundTrip() throws {
        let original = UVDataPoint(latitude: 48.8566, longitude: 2.3522, uvIndex: 4.2, time: Date())
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UVDataPoint.self, from: data)
        #expect(decoded == original)
    }
}
