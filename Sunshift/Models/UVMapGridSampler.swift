import Foundation

// Generates an evenly-spaced geographic grid of sample coordinates around a center point.
// Used to build the set of locations the UV Map requests forecast data for. Pure logic
// only: no networking, caching, or map rendering.
enum UVMapGridSampler {

    static let defaultGridSize = 5
    static let defaultSpanDegrees: Double = 1.0

    // Upper bound on the total span (edge to edge) a grid may cover. Guards against
    // building a grid so wide that sample points are no longer locally meaningful.
    static let maxSpanDegrees: Double = 20.0

    // Generates `gridSize x gridSize` coordinates evenly spaced across a square region
    // centered on `center`, spanning `spanDegrees` of latitude and longitude in total.
    //
    // - `gridSize` below 1 is treated as 1; a `gridSize` of 1 returns just the center point.
    // - `spanDegrees` <= 0 collapses the grid onto the center point.
    // - `spanDegrees` above `maxSpanDegrees` is clamped (region-too-large guard).
    // - Latitudes are clamped to [-90, 90]; longitudes are wrapped into [-180, 180].
    static func generateGrid(
        center: UVForecastCoordinate,
        gridSize: Int = defaultGridSize,
        spanDegrees: Double = defaultSpanDegrees
    ) -> [UVForecastCoordinate] {
        let size = max(1, gridSize)
        let span = min(max(0, spanDegrees), maxSpanDegrees)

        guard size > 1 else { return [center] }

        let step = span / Double(size - 1)
        let start = -span / 2

        var coordinates: [UVForecastCoordinate] = []
        coordinates.reserveCapacity(size * size)

        for row in 0..<size {
            let latitude = clampLatitude(center.latitude + start + step * Double(row))
            for column in 0..<size {
                let longitude = wrapLongitude(center.longitude + start + step * Double(column))
                coordinates.append(UVForecastCoordinate(latitude: latitude, longitude: longitude))
            }
        }
        return coordinates
    }

    private static func clampLatitude(_ latitude: Double) -> Double {
        min(max(latitude, -90), 90)
    }

    private static func wrapLongitude(_ longitude: Double) -> Double {
        var wrapped = longitude.truncatingRemainder(dividingBy: 360)
        if wrapped > 180 { wrapped -= 360 }
        if wrapped < -180 { wrapped += 360 }
        return wrapped
    }
}
