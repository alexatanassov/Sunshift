import SwiftUI
import MapKit
import CoreLocation

// Shows real forecast UV data as a soft local heat overlay over a physical map: sample
// points near the active coordinate blend into translucent, radial-gradient-style circles
// rather than a scattered grid of pins. Purely descriptive: UV Index bands only, no health,
// safety, or sunscreen guidance of any kind.
struct UVMapView: View {
    let coordinate: UVForecastCoordinate
    private let spanDegrees: Double

    @State private var viewModel: UVMapViewModel
    @State private var cameraPosition: MapCameraPosition

    init(
        coordinate: UVForecastCoordinate,
        spanDegrees: Double = UVMapGridSampler.defaultSpanDegrees,
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
            ForEach(nearbyPoints) { point in
                heatBlobContent(for: point)
            }
            ForEach(nearbyPoints) { point in
                Annotation("", coordinate: point.coordinate) {
                    UVMarker(point: point)
                }
            }
        }
    }

    // Renders one sample as a soft blob: three concentric circles of increasing opacity
    // toward the center, anchored to the sample's real coordinate. MapKit projects these
    // natively, so they stay correctly placed and sized through pan and zoom with no
    // screen-space math, and neighboring blobs visually blend where they overlap.
    @MapContentBuilder
    private func heatBlobContent(for point: UVDataPoint) -> some MapContent {
        let color = point.category.markerColor
        let radius = heatBlobRadiusMeters
        MapCircle(center: point.coordinate, radius: radius)
            .foregroundStyle(color.opacity(0.10))
        MapCircle(center: point.coordinate, radius: radius * 0.6)
            .foregroundStyle(color.opacity(0.18))
        MapCircle(center: point.coordinate, radius: radius * 0.32)
            .foregroundStyle(color.opacity(0.28))
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
    // `UVHeatOverlayConfig.localRadiusMiles` of the active coordinate. This is what keeps
    // the overlay feeling like a local patch around "here" rather than covering the full
    // fetched grid edge to edge.
    private var nearbyPoints: [UVDataPoint] {
        let center = activeCenterCoordinate
        return gridPoints.filter { $0.coordinate.distanceMiles(to: center) <= UVHeatOverlayConfig.localRadiusMiles }
    }

    private var activeCenterCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
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

// Tunable parameters for the local UV heat overlay. Adjust `localRadiusMiles` to widen or
// narrow how far from the active coordinate the overlay reaches, e.g. 20, 25, or 30 miles.
private enum UVHeatOverlayConfig {
    static let localRadiusMiles: Double = 25
    static let metersPerMile: Double = 1609.34
    // How far a blob spreads past the spacing to its nearest neighbor, so adjacent blobs
    // overlap and blend rather than leaving hard edges or visible gaps.
    static let blobOverlapFactor: Double = 1.15
}

private extension CLLocationCoordinate2D {
    func distanceMiles(to other: CLLocationCoordinate2D) -> Double {
        let here = CLLocation(latitude: latitude, longitude: longitude)
        let there = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return here.distance(from: there) / UVHeatOverlayConfig.metersPerMile
    }
}

// MARK: - Marker

// A small, subtle dot rather than a large numbered pin: the heat overlay now carries the
// UV value visually, so the marker just marks the sample location without competing for
// attention. The exact index stays available to VoiceOver.
private struct UVMarker: View {
    let point: UVDataPoint

    var body: some View {
        Circle()
            .fill(.white.opacity(0.85))
            .frame(width: 6, height: 6)
            .overlay(Circle().stroke(point.category.markerColor.opacity(0.7), lineWidth: 1))
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 0.5)
            .accessibilityLabel("UV index \(indexText), \(point.category.displayName)")
    }

    private var indexText: String {
        String(Int(point.uvIndex.rounded()))
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
        spanDegrees: UVMapGridSampler.defaultSpanDegrees
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
