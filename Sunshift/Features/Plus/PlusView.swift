import SwiftUI

struct PlusView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 72))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [SunshiftColor.sunrise, SunshiftColor.sunset],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Sunshift Plus")
                            .font(SunshiftFont.display())
                        Text("Unlock everything the sun has to offer.")
                            .font(SunshiftFont.body())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal)

                    // Feature teasers
                    VStack(spacing: 12) {
                        PlusFeatureRow(icon: "bell.badge.fill", color: SunshiftColor.sunrise, title: "Unlimited Routines", detail: "Free tier is limited to 2 active routines")
                        PlusFeatureRow(icon: "location.fill", color: SunshiftColor.sky, title: "Unlimited Locations", detail: "Pin as many places as you need")
                        PlusFeatureRow(icon: "chart.line.uptrend.xyaxis", color: .green, title: "Solar History", detail: "Day-length trends and seasonal insights")
                        PlusFeatureRow(icon: "app.badge.fill", color: SunshiftColor.sunset, title: "Home Screen Widgets", detail: "Live sunrise and sunset right on your home screen")
                    }
                    .padding(.horizontal)

                    // CTA
                    Button(action: {}) {
                        Text("Coming Soon")
                            .font(SunshiftFont.headline())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(true)
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Plus")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct PlusFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SunshiftFont.headline())
                Text(detail)
                    .font(SunshiftFont.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    PlusView()
}
