import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(SunshiftColor.sunrise)
                            .symbolEffect(.pulse)
                        Text("Your Solar Day")
                            .font(SunshiftFont.display())
                        Text("Sunrise, solar noon, and sunset — surfaced for where you are, right now.")
                            .font(SunshiftFont.body())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal)

                    // Placeholder event cards
                    VStack(spacing: 12) {
                        PlaceholderEventRow(icon: "sunrise.fill", color: SunshiftColor.sunrise, label: "Sunrise", detail: "6:14 AM")
                        PlaceholderEventRow(icon: "sun.max.fill", color: .yellow, label: "Solar Noon", detail: "1:02 PM")
                        PlaceholderEventRow(icon: "sunset.fill", color: SunshiftColor.sunset, label: "Sunset", detail: "8:11 PM")
                        PlaceholderEventRow(icon: "moon.stars.fill", color: SunshiftColor.sky, label: "Astronomical Twilight", detail: "9:48 PM")
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct PlaceholderEventRow: View {
    let icon: String
    let color: Color
    let label: String
    let detail: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            Text(label)
                .font(SunshiftFont.headline())
            Spacer()
            Text(detail)
                .font(SunshiftFont.body())
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    TodayView()
}
