#if DEBUG
import SwiftUI

struct SolarDebugView: View {
    @Environment(LocationViewModel.self) private var locationViewModel

    private var resolvedLocation: SavedLocation { locationViewModel.resolvedLocation }
    private var isFallback: Bool { locationViewModel.isUsingFallback }

    private var tz: TimeZone {
        TimeZone(identifier: resolvedLocation.timeZoneIdentifier) ?? .current
    }

    private var result: Result<SunSchedule, Error> {
        let location = resolvedLocation
        let tzId = location.timeZoneIdentifier
        let tz = TimeZone(identifier: tzId) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let today = cal.startOfDay(for: Date())
        let input = SunCalculationInput(
            date: today,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneIdentifier: tzId
        )
        return Result { try SunService().sunSchedule(for: input) }
    }

    var body: some View {
        Group {
            switch result {
            case .success(let schedule):
                scheduleList(schedule)
            case .failure(let error):
                ContentUnavailableView(
                    "Calculation Failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            }
        }
        .navigationTitle("Solar Debug")
        .navigationBarTitleDisplayMode(.inline)
        .background(SunshiftColors.softBackground)
    }

    @ViewBuilder
    private func scheduleList(_ s: SunSchedule) -> some View {
        let now = Date()
        let locationName = isFallback
            ? "\(resolvedLocation.name) (Fallback)"
            : resolvedLocation.name
        List {
            Section("Location") {
                debugRow(label: "Name", value: locationName)
                debugRow(label: "Latitude", value: String(format: "%.4f", s.latitude))
                debugRow(label: "Longitude", value: String(format: "%.4f", s.longitude))
                debugRow(label: "Timezone", value: s.timeZoneIdentifier)
                debugRow(label: "Date", value: dateString(s.date))
            }

            Section("Light Events") {
                debugRow(label: "First Light", value: timeString(s.firstLight))
                debugRow(label: "Blue Hour Start", value: timeString(s.blueHourStart))
                debugRow(label: "Sunrise", value: timeString(s.sunrise))
                debugRow(label: "Golden Hour Start", value: timeString(s.goldenHourStart))
                debugRow(label: "Solar Noon", value: timeString(s.solarNoon))
                debugRow(label: "Golden Hour End", value: timeString(s.goldenHourEnd))
                debugRow(label: "Sunset", value: timeString(s.sunset))
                debugRow(label: "Blue Hour End", value: timeString(s.blueHourEnd))
                debugRow(label: "Last Light", value: timeString(s.lastLight))
            }

            Section("Twilight") {
                debugRow(label: "Civil Twilight Start", value: timeString(s.civilTwilightStart))
                debugRow(label: "Civil Twilight End", value: timeString(s.civilTwilightEnd))
            }

            Section("Duration") {
                debugRow(
                    label: "Daylight Duration",
                    value: s.daylightDuration.map { $0.formattedDuration } ?? "N/A"
                )
                debugRow(
                    label: "Daylight Remaining",
                    value: s.daylightRemaining(at: now).map { $0.formattedDaylightRemaining } ?? "N/A"
                )
            }

            Section("Next Event") {
                if let next = s.nextEvent(after: now) {
                    debugRow(label: next.displayName, value: timeString(next.time))
                } else {
                    Text("None remaining today")
                        .font(SunshiftTypography.body())
                        .foregroundStyle(SunshiftColors.secondaryText)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func debugRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.primaryText)
            Spacer()
            Text(value)
                .font(SunshiftTypography.body())
                .foregroundStyle(SunshiftColors.secondaryText)
                .monospacedDigit()
        }
    }

    private func timeString(_ date: Date?) -> String {
        guard let date else { return "N/A" }
        return date.formattedTime(in: tz)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        SolarDebugView()
            .environment(LocationViewModel(subscriptionService: SubscriptionService()))
    }
}
#endif
