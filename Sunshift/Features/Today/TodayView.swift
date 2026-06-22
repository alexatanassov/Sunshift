import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(SunshiftColor.sunrise)
                Text("Today")
                    .font(SunshiftFont.display())
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    TodayView()
}
