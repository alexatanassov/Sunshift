import SwiftUI

struct PlusView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "sun.max.trianglebadge.exclamationmark")
                    .font(.system(size: 72))
                    .foregroundStyle(SunshiftColor.sunrise)
                Text("Sunshift Plus")
                    .font(SunshiftFont.display())
                Text("Coming soon")
                    .font(SunshiftFont.body())
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Plus")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    PlusView()
}
