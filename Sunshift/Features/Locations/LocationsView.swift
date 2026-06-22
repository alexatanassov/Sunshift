import SwiftUI

struct LocationsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "map")
                    .font(.system(size: 72))
                    .foregroundStyle(SunshiftColor.sky)
                Text("Locations")
                    .font(SunshiftFont.display())
            }
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    LocationsView()
}
