import SwiftUI

struct RoutinesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 72))
                    .foregroundStyle(SunshiftColor.sky)
                Text("Routines")
                    .font(SunshiftFont.display())
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    RoutinesView()
}
