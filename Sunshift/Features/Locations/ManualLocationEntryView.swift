import SwiftUI

struct ManualLocationEntryView: View {
    @Environment(LocationViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var latitudeText = ""
    @State private var longitudeText = ""
    @State private var timezoneText = ""
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SunshiftSpacing.lg) {
                    formCard
                    if let error = saveError {
                        saveErrorBanner(error)
                    }
                    examplesCard
                }
                .padding(.horizontal, SunshiftSpacing.md)
                .padding(.top, SunshiftSpacing.md)
                .padding(.bottom, SunshiftSpacing.xxl)
            }
            .background(SunshiftColors.softBackground)
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { attemptSave() }
                        .disabled(!formIsValid)
                        .tint(SunshiftColors.sunsetAmber)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            fieldRow(label: "Location Name") {
                TextField("San Diego", text: $name)
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.primaryText)
                    .textInputAutocapitalization(.words)
            }

            Divider().padding(.horizontal, SunshiftSpacing.md)

            fieldRow(label: "Latitude", errorMessage: latitudeError) {
                TextField("32.7157", text: $latitudeText)
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.primaryText)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Divider().padding(.horizontal, SunshiftSpacing.md)

            fieldRow(label: "Longitude", errorMessage: longitudeError) {
                TextField("-117.1611", text: $longitudeText)
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.primaryText)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Divider().padding(.horizontal, SunshiftSpacing.md)

            fieldRow(label: "Timezone Identifier", errorMessage: timezoneError) {
                TextField("America/Los_Angeles", text: $timezoneText)
                    .font(SunshiftTypography.body())
                    .foregroundStyle(SunshiftColors.primaryText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }

    @ViewBuilder
    private func fieldRow<F: View>(
        label: String,
        errorMessage: String? = nil,
        @ViewBuilder field: () -> F
    ) -> some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.xs) {
            Text(label)
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.secondaryText)
            field()
            if let error = errorMessage {
                Text(error)
                    .font(SunshiftTypography.caption())
                    .foregroundStyle(.red.opacity(0.75))
            }
        }
        .padding(SunshiftSpacing.md)
    }

    // MARK: - Save Error Banner

    @ViewBuilder
    private func saveErrorBanner(_ message: String) -> some View {
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
                saveError = nil
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(SunshiftColors.secondaryText)
            }
        }
        .padding(SunshiftSpacing.md)
        .background(
            SunshiftColors.sunsetAmber.opacity(0.1),
            in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium)
        )
    }

    // MARK: - Examples Card

    private var examplesCard: some View {
        VStack(alignment: .leading, spacing: SunshiftSpacing.sm) {
            Text("Tap an example to fill the form")
                .font(SunshiftTypography.caption())
                .foregroundStyle(SunshiftColors.secondaryText)

            exampleButton(name: "San Diego", lat: "32.7157",   lon: "-117.1611", tz: "America/Los_Angeles")
            Divider()
            exampleButton(name: "New York",  lat: "40.7128",   lon: "-74.0060",  tz: "America/New_York")
            Divider()
            exampleButton(name: "London",    lat: "51.5074",   lon: "-0.1278",   tz: "Europe/London")
        }
        .padding(SunshiftSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SunshiftColors.cardBackground, in: RoundedRectangle(cornerRadius: SunshiftCornerRadius.medium))
        .cardShadow()
    }

    private func exampleButton(name: String, lat: String, lon: String, tz: String) -> some View {
        Button {
            self.name = name
            latitudeText = lat
            longitudeText = lon
            timezoneText = tz
            saveError = nil
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(SunshiftTypography.headline())
                    .foregroundStyle(SunshiftColors.primaryText)
                Text("\(lat), \(lon)  \(tz)")
                    .font(SunshiftTypography.caption())
                    .foregroundStyle(SunshiftColors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Validation

    private var trimmedName: String     { name.trimmingCharacters(in: .whitespaces) }
    private var trimmedLatitude: String  { latitudeText.trimmingCharacters(in: .whitespaces) }
    private var trimmedLongitude: String { longitudeText.trimmingCharacters(in: .whitespaces) }
    private var trimmedTimezone: String  { timezoneText.trimmingCharacters(in: .whitespaces) }

    private var latitudeValue: Double?  { Double(trimmedLatitude) }
    private var longitudeValue: Double? { Double(trimmedLongitude) }

    private var nameIsValid: Bool { !trimmedName.isEmpty }
    private var latitudeIsValid: Bool {
        guard let lat = latitudeValue else { return false }
        return lat >= -90 && lat <= 90
    }
    private var longitudeIsValid: Bool {
        guard let lon = longitudeValue else { return false }
        return lon >= -180 && lon <= 180
    }
    private var timezoneIsValid: Bool {
        !trimmedTimezone.isEmpty && TimeZone(identifier: trimmedTimezone) != nil
    }
    private var formIsValid: Bool {
        nameIsValid && latitudeIsValid && longitudeIsValid && timezoneIsValid
    }

    // Shown only when the field has content but the value is invalid.
    private var latitudeError: String? {
        guard !trimmedLatitude.isEmpty, !latitudeIsValid else { return nil }
        return "Must be between -90 and 90"
    }
    private var longitudeError: String? {
        guard !trimmedLongitude.isEmpty, !longitudeIsValid else { return nil }
        return "Must be between -180 and 180"
    }
    private var timezoneError: String? {
        guard !trimmedTimezone.isEmpty, !timezoneIsValid else { return nil }
        return "Not a recognized timezone identifier"
    }

    // MARK: - Save

    private func attemptSave() {
        saveError = nil
        guard formIsValid, let lat = latitudeValue, let lon = longitudeValue else { return }

        if !vm.canAddManualLocation {
            saveError = "You have reached the free plan limit of 1 saved location. Upgrade to Sunshift Plus to save more."
            return
        }

        let location = SavedLocation(
            name: trimmedName,
            latitude: lat,
            longitude: lon,
            timeZoneIdentifier: trimmedTimezone,
            source: .manual
        )
        vm.saveManualLocation(location)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let sub = SubscriptionService()
    let vm = LocationViewModel(subscriptionService: sub)
    return ManualLocationEntryView()
        .environment(vm)
}
