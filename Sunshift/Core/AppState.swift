import Foundation

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "sunshift.hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "sunshift.hasCompletedOnboarding") }
    }
}
