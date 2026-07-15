import Testing
@testable import Sunshift

struct UVMapGridSamplerTests {

    private let center = UVForecastCoordinate(latitude: 32.75, longitude: -117.15)

    @Test func defaultGridReturns25Points() {
        let grid = UVMapGridSampler.generateGrid(center: center)
        #expect(grid.count == 25)
    }

    @Test func gridIsCenteredOnInputCoordinate() {
        let grid = UVMapGridSampler.generateGrid(center: center)
        #expect(grid.contains(center))
    }

    @Test func latitudeAndLongitudeSpacingIsPredictable() {
        let span = UVMapGridSampler.defaultSpanDegrees
        let gridSize = UVMapGridSampler.defaultGridSize
        let grid = UVMapGridSampler.generateGrid(center: center, gridSize: gridSize, spanDegrees: span)
        let expectedStep = span / Double(gridSize - 1)

        // Grid is row-major: first `gridSize` entries share the same (minimum) latitude and
        // step across longitude; every `gridSize`-th entry steps across latitude.
        let firstRowLongitudes = grid[0..<gridSize].map(\.longitude)
        for index in 1..<firstRowLongitudes.count {
            let delta = firstRowLongitudes[index] - firstRowLongitudes[index - 1]
            #expect(abs(delta - expectedStep) < 0.0001)
        }

        let firstColumnLatitudes = stride(from: 0, to: grid.count, by: gridSize).map { grid[$0].latitude }
        for index in 1..<firstColumnLatitudes.count {
            let delta = firstColumnLatitudes[index] - firstColumnLatitudes[index - 1]
            #expect(abs(delta - expectedStep) < 0.0001)
        }
    }

    @Test func gridSizeCanBeChanged() {
        let grid = UVMapGridSampler.generateGrid(center: center, gridSize: 3)
        #expect(grid.count == 9)
    }

    @Test func zeroOrNegativeGridSizeFallsBackToSinglePoint() {
        #expect(UVMapGridSampler.generateGrid(center: center, gridSize: 0).count == 1)
        #expect(UVMapGridSampler.generateGrid(center: center, gridSize: -3).count == 1)
    }

    @Test func negativeSpanCollapsesGridOntoCenter() {
        let grid = UVMapGridSampler.generateGrid(center: center, spanDegrees: -10)
        #expect(grid.allSatisfy { $0 == center })
    }

    @Test func excessiveSpanIsClampedToMaxSpan() {
        let grid = UVMapGridSampler.generateGrid(center: center, gridSize: 2, spanDegrees: 1000)
        let latitudes = grid.map(\.latitude)
        let spread = (latitudes.max() ?? 0) - (latitudes.min() ?? 0)
        #expect(spread <= UVMapGridSampler.maxSpanDegrees + 0.0001)
    }

    @Test func generatedCoordinatesStayWithinValidLatitudeLongitudeBounds() {
        let poleAdjacentCenter = UVForecastCoordinate(latitude: 89, longitude: 179)
        let grid = UVMapGridSampler.generateGrid(center: poleAdjacentCenter, gridSize: 5, spanDegrees: 20)

        for coordinate in grid {
            #expect((-90...90).contains(coordinate.latitude))
            #expect((-180...180).contains(coordinate.longitude))
        }
    }
}
