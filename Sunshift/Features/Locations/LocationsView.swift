import SwiftUI

struct LocationsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(SunshiftColor.sky)
                        Text("Your Locations")
                            .font(SunshiftFont.display())
                        Text("Pin the places that matter — home, office, a favourite trail — and get accurate solar times for each one.")
                            .font(SunshiftFont.body())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal)

                    // Placeholder location rows
                    VStack(spacing: 12) {
                        PlaceholderLocationRow(icon: "house.fill", color: SunshiftColor.sunrise, name: "Home", detail: "San Francisco, CA")
                        PlaceholderLocationRow(icon: "briefcase.fill", color: SunshiftColor.sky, name: "Office", detail: "South of Market")
                        PlaceholderLocationRow(icon: "mountain.2.fill", color: .green, name: "Weekend Hike", detail: "Marin Headlands")
                    }
                    .padding(.horizontal)

                    Label("Location pinning is coming in Stage 1", systemImage: "clock")
                        .font(SunshiftFont.caption())
                        .foregroundStyle(.tertiary)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct PlaceholderLocationRow: View {
    let icon: String
    let color: Color
    let name: String
    let detail: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(SunshiftFont.headline())
                Text(detail)
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
    LocationsView()
}
