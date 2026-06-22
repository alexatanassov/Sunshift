import SwiftUI

struct RoutinesView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(SunshiftColor.sky)
                        Text("Solar Routines")
                            .font(SunshiftFont.display())
                        Text("Create habits that fire at sunrise, sunset, or any solar milestone — every day, automatically.")
                            .font(SunshiftFont.body())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal)

                    // Placeholder routine rows
                    VStack(spacing: 12) {
                        PlaceholderRoutineRow(icon: "sunrise.fill", color: SunshiftColor.sunrise, title: "Morning Wind-Up", trigger: "At Sunrise")
                        PlaceholderRoutineRow(icon: "sun.max.fill", color: .yellow, title: "Midday Check-In", trigger: "At Solar Noon")
                        PlaceholderRoutineRow(icon: "sunset.fill", color: SunshiftColor.sunset, title: "Evening Wind-Down", trigger: "30 min before Sunset")
                    }
                    .padding(.horizontal)

                    // CTA hint
                    Label("Routines are coming in Stage 1", systemImage: "clock")
                        .font(SunshiftFont.caption())
                        .foregroundStyle(.tertiary)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct PlaceholderRoutineRow: View {
    let icon: String
    let color: Color
    let title: String
    let trigger: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SunshiftFont.headline())
                Text(trigger)
                    .font(SunshiftFont.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    RoutinesView()
}
