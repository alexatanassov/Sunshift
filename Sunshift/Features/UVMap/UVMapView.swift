import SwiftUI
import MapKit
import CoreLocation
import UIKit

// Shows real forecast UV data as one soft local UV field over a physical map, rather than a
// scattered grid of individual circles or pins. The overlay is an interpolated forecast
// visualization derived from a handful of sample points: it communicates roughly how UV
// varies across the local area, not an exact UV value at every pixel. Purely descriptive:
// UV Index bands only, no health, safety, or sunscreen guidance of any kind.
struct UVMapView: View {
    let coordinate: UVForecastCoordinate
    private let spanDegrees: Double

    @State private var viewModel: UVMapViewModel
    @State private var cameraPosition: MapCameraPosition

    init(
        coordinate: UVForecastCoordinate,
        spanDegrees: Double = UVMapRadiusConfig.defaultSpanDegrees,
        viewModel: UVMapViewModel = UVMapViewModel()
    ) {
        self.coordinate = coordinate
        self.spanDegrees = spanDegrees
        _viewModel = State(initialValue: viewModel)
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                // A little wider than the sample grid itself, so edge markers aren't clipped.
                span: MKCoordinateSpan(
                    latitudeDelta: spanDegrees * 1.3,
                    longitudeDelta: spanDegrees * 1.3
                )
            )
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                mapLayer

                VStack(spacing: SunshiftSpacing.sm) {
                    statusBanner
                        .padding(.horizontal, SunshiftSpacing.md)
                        .padding(.top, SunshiftSpacing.sm)

                    Spacer()

                    if isShowingData {
                        UVMapLegend()
                            .padding(.horizontal, SunshiftSpacing.md)
                        attributionText
                            .padding(.bottom, SunshiftSpacing.sm)
                    }
                }
            }
            .navigationTitle("UV Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    refreshButton
                }
            }
            .task {
                await viewModel.load(center: coordinate, spanDegrees: spanDegrees)
            }
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            localFieldContent
        }
    }

    // The local UV field: one broad circle spanning the configured local radius sets the
    // overall tone for the area, and a soft, many-step blob per sample blends on top of it to
    // carry local variation. Sample points still project natively via MapCircle, so placement
    // and sizing stay correct through pan and zoom with no screen-space math. This whole layer
    // is an interpolated visualization between discrete sample points, not a per-pixel reading.
    @MapContentBuilder
    private var localFieldContent: some MapContent {
        if let bounds = localValueBounds {
            MapCircle(
                center: activeCenterCoordinate,
                radius: UVMapRadiusConfig.defaultRadiusMiles * UVHeatOverlayConfig.metersPerMile
            )
            .foregroundStyle(UVFieldColor.baseColor(forUVIndex: bounds.mean).opacity(0.07))

            ForEach(nearbyPoints) { point in
                fieldBlobContent(for: point, bounds: bounds)
            }
        }
    }

    // Renders one sample as a soft blob with several closely-spaced, low-opacity steps rather
    // than a few widely-spaced rings, so it reads as a continuous falloff toward its edges
    // instead of visible concentric bands. Neighboring blobs are sized to overlap generously,
    // so they blend into each other rather than standing out as separate bubbles.
    @MapContentBuilder
    private func fieldBlobContent(for point: UVDataPoint, bounds: LocalValueBounds) -> some MapContent {
        let color = UVFieldColor.baseColor(forUVIndex: point.uvIndex)
        let opacity = UVFieldColor.fillOpacity(forUVIndex: point.uvIndex, bounds: bounds)
        let radius = heatBlobRadiusMeters
        MapCircle(center: point.coordinate, radius: radius)
            .foregroundStyle(color.opacity(opacity * 0.30))
        MapCircle(center: point.coordinate, radius: radius * 0.72)
            .foregroundStyle(color.opacity(opacity * 0.50))
        MapCircle(center: point.coordinate, radius: radius * 0.48)
            .foregroundStyle(color.opacity(opacity * 0.72))
        MapCircle(center: point.coordinate, radius: radius * 0.24)
            .foregroundStyle(color.opacity(opacity))
    }

    private var gridPoints: [UVDataPoint] {
        switch viewModel.state {
        case .loaded(let snapshot, _):
            return snapshot.points
        case .idle, .loading, .failed, .regionTooLarge:
            return []
        }
    }

    // The sample points the heat overlay and markers actually render: only those within
    // `UVMapRadiusConfig.defaultRadiusMiles` of the active coordinate. This is what keeps
    // the overlay feeling like a local patch around "here" rather than covering the full
    // fetched grid edge to edge.
    private var nearbyPoints: [UVDataPoint] {
        let center = activeCenterCoordinate
        return gridPoints.filter { $0.coordinate.distanceMiles(to: center) <= UVMapRadiusConfig.defaultRadiusMiles }
    }

    private var activeCenterCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    // The min, max, and mean UV Index across the currently loaded local sample points. This is
    // the "local color normalization layer": the overlay's contrast is drawn from how values
    // vary within this specific loaded radius, not from the full 0-16 UV Index scale, so small
    // but real nearby differences stay visible instead of being flattened into one color.
    private var localValueBounds: LocalValueBounds? {
        let values = nearbyPoints.map(\.uvIndex)
        guard let low = values.min(), let high = values.max() else { return nil }
        let mean = values.reduce(0, +) / Double(values.count)
        return LocalValueBounds(min: low, max: high, mean: mean)
    }

    // Sizes each blob so it overlaps its nearest neighbor rather than leaving gaps or hard
    // edges. Derives spacing from however many points actually came back (assumed square,
    // e.g. 25 for a 5x5 grid) rather than a hardcoded grid size, so this keeps working
    // unchanged if the sampler's grid size later grows to 9x9 or 11x11.
    private var heatBlobRadiusMeters: Double {
        let sampleCount = max(gridPoints.count, 1)
        let gridSize = max(2, Int(Double(sampleCount).squareRoot().rounded()))
        let spacingDegrees = spanDegrees / Double(gridSize - 1)
        let center = activeCenterCoordinate
        let neighbor = CLLocationCoordinate2D(latitude: center.latitude + spacingDegrees, longitude: center.longitude)
        let spacingMiles = center.distanceMiles(to: neighbor)
        return spacingMiles * UVHeatOverlayConfig.blobOverlapFactor * UVHeatOverlayConfig.metersPerMile
    }

    private var isShowingData: Bool {
        if case .loaded = viewModel.state { return true }
        return false
    }

    // MARK: - Status banner

    @ViewBuilder
    private var statusBanner: some View {
        switch viewModel.state {
        case .idle, .loading:
            UVMapStatusBanner(systemImage: nil, message: "Loading UV data…", showsSpinner: true)
        case .loaded(_, let isStale):
            if isStale {
                UVMapStatusBanner(
                    systemImage: "clock.arrow.circlepath",
                    message: "Showing saved data from earlier.",
                    showsSpinner: false
                )
            }
        case .failed(let message):
            UVMapStatusBanner(systemImage: "exclamationmark.triangle", message: message, showsSpinner: false)
        case .regionTooLarge:
            UVMapStatusBanner(systemImage: "map", message: "This region is too large to map.", showsSpinner: false)
        }
    }

    // MARK: - Refresh

    private var refreshButton: some View {
        Button {
            Task { await viewModel.refresh(center: coordinate, spanDegrees: spanDegrees) }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .tint(SunshiftColors.sunsetAmber)
        .disabled(isRefreshing)
    }

    private var isRefreshing: Bool {
        switch viewModel.state {
        case .idle, .loading: return true
        default: return false
        }
    }

    // MARK: - Attribution

    private var attributionText: some View {
        Text("UV data from Open-Meteo")
            .font(SunshiftTypography.caption(10))
            .foregroundStyle(SunshiftColors.secondaryText.opacity(0.7))
    }
}

// MARK: - Heat overlay configuration

// Tunable parameters for the local UV heat overlay. The overlay's reach itself is governed
// by `UVMapRadiusConfig.defaultRadiusMiles`, the shared radius default, so it can't drift
// out of sync with the sampling grid's span.
private enum UVHeatOverlayConfig {
    static let metersPerMile: Double = 1609.34
    // How far a blob spreads past the spacing to its nearest neighbor. Generous overlap is
    // what makes neighboring blobs read as one continuous field rather than separate bubbles.
    static let blobOverlapFactor: Double = 1.6
}

// MARK: - Local color normalization

// The min, max, and mean UV Index across the sample points currently loaded within the local
// radius. Drives the overlay's local color normalization: contrast is drawn from this window,
// not the full UV Index scale.
private struct LocalValueBounds {
    let min: Double
    let max: Double
    let mean: Double
}

// Maps a UV Index value to a color and a fill opacity for the local field overlay.
//
// Two things are combined here, deliberately kept separate:
// - `baseColor` is an absolute, continuous mapping from UV Index to color: it interpolates
//   smoothly between the same category anchor colors used in the legend, so a reading of 6.2
//   and one of 7.8 (both nominally "High") still render as visibly different shades instead
//   of identical orange.
// - `fillOpacity` is the local normalization layer: it stretches visible contrast across
//   whatever min/max is actually loaded nearby, so small real differences stay legible.
//
// The two are combined rather than one alone so contrast is drawn out locally without ever
// remapping a value's hue away from what it would show anywhere else on the map — bounded,
// so the overlay can't become misleading about the absolute UV level.
private enum UVFieldColor {
    // Below this much spread (in UV Index units) across the loaded local radius, differences
    // are treated as noise rather than meaningful signal: the overlay falls back to a calm,
    // mostly uniform look rather than stretching a tiny gap into exaggerated contrast.
    private static let minMeaningfulRange: Double = 1.0

    // Bounds on how much the local normalization layer can vary fill opacity, so contrast
    // stays gentle even at the extremes of a wide local range.
    private static let baseOpacity: Double = 0.12
    private static let opacityContrastRange: Double = 0.14
    private static let uniformOpacity: Double = 0.16

    // Continuous color anchors across the standard UV Index scale, matching the legend's
    // category colors. Values interpolate between neighboring anchors rather than snapping.
    private static let stops: [(uv: Double, color: Color)] = [
        (0, .green),
        (3, .yellow),
        (6, .orange),
        (8, .red),
        (11, SunshiftColors.duskPurple)
    ]

    static func baseColor(forUVIndex uvIndex: Double) -> Color {
        let lowestStop = stops[0]
        let highestStop = stops[stops.count - 1]
        let clamped = min(max(uvIndex, lowestStop.uv), highestStop.uv)

        for index in 0..<(stops.count - 1) {
            let lower = stops[index]
            let upper = stops[index + 1]
            guard clamped <= upper.uv else { continue }
            let span = upper.uv - lower.uv
            let t = span > 0 ? (clamped - lower.uv) / span : 0
            return lower.color.blended(with: upper.color, amount: t)
        }
        return highestStop.color
    }

    static func fillOpacity(forUVIndex uvIndex: Double, bounds: LocalValueBounds) -> Double {
        let range = bounds.max - bounds.min
        guard range >= minMeaningfulRange else { return uniformOpacity }
        let t = (uvIndex - bounds.min) / range
        return baseOpacity + t * opacityContrastRange
    }
}

private extension Color {
    // Linear blend between two colors' RGB components. Good enough for a smooth-looking
    // overlay gradient between adjacent legend colors; not intended for perceptually-uniform
    // color science.
    func blended(with other: Color, amount: Double) -> Color {
        let t = max(0, min(1, amount))
        let a = UIColor(self).resolvedComponents
        let b = UIColor(other).resolvedComponents
        return Color(
            red: a.r + (b.r - a.r) * t,
            green: a.g + (b.g - a.g) * t,
            blue: a.b + (b.b - a.b) * t
        )
    }
}

private extension UIColor {
    var resolvedComponents: (r: Double, g: Double, b: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

private extension CLLocationCoordinate2D {
    func distanceMiles(to other: CLLocationCoordinate2D) -> Double {
        let here = CLLocation(latitude: latitude, longitude: longitude)
        let there = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return here.distance(from: there) / UVHeatOverlayConfig.metersPerMile
    }
}

private extension UVDataPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension UVCategory {
    // Standard EPA/WHO UV Index color scale: green through purple.
    var markerColor: Color {
        switch self {
        case .low:      return .green
        case .moderate: return .yellow
        case .high:     return .orange
        case .veryHigh: return .red
        case .extreme:  return SunshiftColors.duskPurple
        }
    }
}

// MARK: - Legend

private struct UVMapLegend: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SunshiftSpacing.md) {
                ForEach(UVCategory.allCases) { category in
                    HStack(spacing: SunshiftSpacing.xs) {
                        Circle()
                            .fill(category.markerColor)
                            .frame(width: 8, height: 8)
                        Text(category.displayName)
                            .font(SunshiftTypography.caption(11))
                            .foregroundStyle(SunshiftColors.primaryText)
                    }
                }
            }
            .padding(.horizontal, SunshiftSpacing.md)
            .padding(.vertical, SunshiftSpacing.sm)
        }
        .background(SunshiftColors.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

// MARK: - Status banner

private struct UVMapStatusBanner: View {
    let systemImage: String?
    let message: String
    let showsSpinner: Bool

    var body: some View {
        HStack(spacing: SunshiftSpacing.sm) {
            if showsSpinner {
                ProgressView()
            } else if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(SunshiftColors.sunsetAmber)
            }
            Text(message)
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, SunshiftSpacing.md)
        .padding(.vertical, SunshiftSpacing.sm)
        .background(SunshiftColors.cardBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

// MARK: - Previews

private enum UVMapPreviewData {
    static let coordinate = UVForecastCoordinate(latitude: 32.7157, longitude: -117.1611)

    static func points(baseIndex: Double) -> [UVDataPoint] {
        UVMapGridSampler.generateGrid(center: coordinate).enumerated().map { offset, sampleCoordinate in
            UVDataPoint(
                latitude: sampleCoordinate.latitude,
                longitude: sampleCoordinate.longitude,
                uvIndex: max(0, baseIndex + Double(offset % 5) - 2),
                time: Date()
            )
        }
    }
}

// Returns fixed, static data instantly; makes no network requests. Safe for previews.
private struct PreviewUVForecastService: UVForecastServiceProtocol {
    let result: Result<[UVDataPoint], Error>

    func fetchCurrentUVIndex(for coordinates: [UVForecastCoordinate]) async throws -> [UVDataPoint] {
        try result.get()
    }
}

private func previewCacheStore(prepopulatedWith snapshot: UVGridSnapshot? = nil) -> UVCacheStore {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("UVMapPreviewCache-\(UUID().uuidString)", isDirectory: true)
    let store = UVCacheStore(directoryURL: directory)
    if let snapshot {
        store.save(snapshot)
    }
    return store
}

#Preview("Loaded") {
    UVMapView(
        coordinate: UVMapPreviewData.coordinate,
        viewModel: UVMapViewModel(
            service: PreviewUVForecastService(result: .success(UVMapPreviewData.points(baseIndex: 6))),
            cacheStore: previewCacheStore()
        )
    )
}

#Preview("Stale cache") {
    let regionKey = UVCacheStore.regionKey(
        center: UVMapPreviewData.coordinate,
        spanDegrees: UVMapRadiusConfig.defaultSpanDegrees
    )
    let staleSnapshot = UVGridSnapshot(
        points: UVMapPreviewData.points(baseIndex: 3),
        regionKey: regionKey,
        fetchedAt: Date().addingTimeInterval(-2 * 60 * 60)
    )
    return UVMapView(
        coordinate: UVMapPreviewData.coordinate,
        viewModel: UVMapViewModel(
            service: PreviewUVForecastService(result: .failure(UVForecastError.missingUVData)),
            cacheStore: previewCacheStore(prepopulatedWith: staleSnapshot)
        )
    )
}

#Preview("Failed") {
    UVMapView(
        coordinate: UVMapPreviewData.coordinate,
        viewModel: UVMapViewModel(
            service: PreviewUVForecastService(result: .failure(UVForecastError.missingUVData)),
            cacheStore: previewCacheStore()
        )
    )
}

#Preview("Region too large") {
    UVMapView(
        coordinate: UVMapPreviewData.coordinate,
        spanDegrees: UVMapGridSampler.maxSpanDegrees + 1,
        viewModel: UVMapViewModel(
            service: PreviewUVForecastService(result: .success(UVMapPreviewData.points(baseIndex: 6))),
            cacheStore: previewCacheStore()
        )
    )
}
