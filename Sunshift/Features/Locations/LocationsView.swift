import SwiftUI

struct LocationsView: View {
    @Environment(LocationViewModel.self) private var vm
    @State private var showingManualEntry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.lg) {
                    permissionSection

                    LocationActiveCard()

                    if isAuthorized {
                        LocationCurrentControls()
                    }

                    if let error = vm.userFacingError {
                        LocationErrorBanner(message: error)
                    }

                    LocationSavedSection()

                    Spacer(minLength: SunshiftSpacing.xxl)
                }
                .padding(.horizontal, SunshiftSpacing.md)
                .padding(.top, SunshiftSpacing.md)
            }
            .background(SunshiftColors.softBackground)
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingManualEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(SunshiftColors.sunsetAmber)
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualLocationEntryView()
                    .environment(vm)
            }
        }
        .background(SunshiftColors.softBackground)
    }

    @ViewBuilder
    private var permissionSection: some View {
        switch vm.permissionStatus {
        case .notDetermined:
            LocationPermissionExplainCard()
        case .denied, .restricted:
            LocationPermissionDeniedCard()
        case .authorizedWhenInUse, .authorizedAlways:
            EmptyView()
        }
    }

    private var isAuthorized: Bool {
        vm.permissionStatus == .authorizedWhenInUse || vm.permissionStatus == .authorizedAlways
    }
}

// MARK: - Active Location Card

private struct LocationActiveCard: View {
    @Environment(LocationViewModel.self) private var vm

    var body: some View {
        let location = vm.resolvedLocation
        VStack(alignment: .leading, spacing: SunshiftSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Label("Active Location", systemImage: "location.fill")
                    .font(SunshiftTypography.caption())
                    .foregroundStyle(SunshiftColors.secondaryText)
                Spacer()
                if vm.isUsingFallback {
                    Text("Fallback")
                        .font(SunshiftTypography.caption())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(SunshiftColors.sunsetAmber.opacity(0.85), in: Capsule())
                }
            }

            Text(location.name)
                .font(SunshiftTypography.title())
                .foregroundStyle(SunshiftColors.primaryText)

            if !location.subtitle.isEmpty && location.subtitle != location.name {
                Text(location.subtitle)
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.secondaryText)
            }

            if vm.isUsingFallback {
                Divider()
                    .padding(.top, SunshiftSpacing.xs)
                Text("Showing solar times for San Diego. Set your location to see accurate times for where you are.")
                    .font(SunshiftTypography.caption())
                    .foregroundStyle(SunshiftColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(SunshiftSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

// MARK: - Permission Cards

private struct LocationPermissionExplainCard: View {
    @Environment(LocationViewModel.self) private var vm

    var body: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.md) {
            Label("About Location Access", systemImage: "location.circle")
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.sunsetAmber)

            Text("Sunshift uses your location to calculate sunrise, sunset, and light routines for where you are.")
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await vm.useCurrentLocation() }
            } label: {
                HStack {
                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    Text("Use Current Location")
                        .font(SunshiftTypography.headline())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SunshiftSpacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(SunshiftColors.sunsetAmber)
            .disabled(vm.isLoading)
        }
        .padding(SunshiftSpacing.md)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

private struct LocationPermissionDeniedCard: View {
    @Environment(LocationViewModel.self) private var vm
    @Environment(\.openURL) private var openURL

    private var message: String {
        if vm.permissionStatus == .restricted {
            return "Location access is restricted on this device. Solar times will be shown for the San Diego fallback."
        }
        return "Location access has been turned off. You can enable it in Settings to let Sunshift calculate sunrise and sunset times for where you are."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.md) {
            Label("Location Access Off", systemImage: "location.slash")
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.secondaryText)

            Text(message)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if vm.permissionStatus == .denied {
                Button {
                    if let url = URL(string: "app-settings:") {
                        openURL(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .font(SunshiftTypography.headline())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SunshiftSpacing.sm)
                }
                .buttonStyle(.bordered)
                .tint(SunshiftColors.secondaryText)
            }
        }
        .padding(SunshiftSpacing.md)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

// MARK: - Current Location Controls

private struct LocationCurrentControls: View {
    @Environment(LocationViewModel.self) private var vm

    private var hasCurrentLocation: Bool {
        vm.activeLocation?.isCurrentLocation == true
    }

    var body: some View {
        VStack(spacing: SunshiftSpacing.sm) {
            Button {
                Task { await vm.useCurrentLocation() }
            } label: {
                HStack {
                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    Text(hasCurrentLocation ? "Update Current Location" : "Use Current Location")
                        .font(SunshiftTypography.headline())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SunshiftSpacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(SunshiftColors.sunsetAmber)
            .disabled(vm.isLoading)

            if hasCurrentLocation {
                Button {
                    Task { await vm.refreshCurrentLocation() }
                } label: {
                    HStack {
                        if vm.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh Current Location")
                            .font(SunshiftTypography.body())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SunshiftSpacing.sm)
                }
                .buttonStyle(.bordered)
                .tint(SunshiftColors.secondaryText)
                .disabled(vm.isLoading)
            }
        }
    }
}

// MARK: - Error Banner

private struct LocationErrorBanner: View {
    let message: String
    @Environment(LocationViewModel.self) private var vm

    var body: some View {
        HStack(alignment: .top, spacing: SunshiftSpacing.sm) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(SunshiftColors.sunsetAmber)
                .padding(.top, 1)
            Text(message)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                vm.userFacingError = nil
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(SunshiftColors.secondaryText)
                    .padding(.top, 1)
            }
        }
        .padding(SunshiftSpacing.md)
        .background(SunshiftColors.sunsetAmber.opacity(0.1), in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
    }
}

// MARK: - Saved Locations Section

private struct LocationSavedSection: View {
    @Environment(LocationViewModel.self) private var vm
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var showingPlus = false

    private var manualLocations: [SavedLocation] {
        vm.savedLocations.filter { !$0.isCurrentLocation }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.sm) {
            Text("Saved Locations")
                .font(SunshiftTypography.headline())
                .foregroundStyle(SunshiftColors.primaryText)
                .padding(.bottom, SunshiftSpacing.xs)

            if manualLocations.isEmpty {
                LocationEmptyState()
            } else {
                ForEach(manualLocations) { location in
                    LocationSavedRow(location: location)
                }
            }

            if !vm.canAddManualLocation {
                LocationPlusUpsell { showingPlus = true }
            }
        }
        .sheet(isPresented: $showingPlus) {
            PlusView()
                .environment(subscriptionService)
        }
    }
}

private struct LocationEmptyState: View {
    var body: some View {
        VStack(spacing: SunshiftSpacing.sm) {
            Image(systemName: "mappin.slash")
                .font(.title2)
                .foregroundStyle(SunshiftColors.secondaryText.opacity(0.4))
            Text("No saved locations yet")
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(SunshiftSpacing.lg)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

private struct LocationSavedRow: View {
    let location: SavedLocation
    @Environment(LocationViewModel.self) private var vm

    private var isActive: Bool { vm.activeLocation?.id == location.id }

    var body: some View {
        HStack(spacing: SunshiftSpacing.sm) {
            Button {
                vm.setActiveLocation(location)
            } label: {
                HStack(spacing: SunshiftSpacing.md) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(
                            isActive ? SunshiftColors.sunsetAmber : SunshiftColors.secondaryText.opacity(0.35)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: SunshiftSpacing.xs) {
                            Text(location.name)
                                .font(SunshiftTypography.headline())
                                .foregroundStyle(SunshiftColors.primaryText)
                            if location.isHomeLocation {
                                Image(systemName: "house.fill")
                                    .font(.caption2)
                                    .foregroundStyle(SunshiftColors.sunrisePeach)
                            }
                        }
                        if !location.subtitle.isEmpty && location.subtitle != location.name {
                            Text(location.subtitle)
                                .font(SunshiftTypography.caption())
                                .foregroundStyle(SunshiftColors.secondaryText)
                        }
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                vm.removeSavedLocation(location)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.red.opacity(0.65))
            }
        }
        .padding(SunshiftSpacing.md)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }
}

private struct LocationPlusUpsell: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: SunshiftSpacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(SunshiftColors.duskPurple)
                Text("Multiple saved locations will be part of Sunshift Plus.")
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(SunshiftSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SunshiftColors.duskPurple.opacity(0.08), in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let sub = SubscriptionService()
    let vm = LocationViewModel(subscriptionService: sub)
    return LocationsView()
        .environment(vm)
        .environment(sub)
}
