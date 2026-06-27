import Foundation

@Observable
final class AppState {
    // Stored so @Observable can track mutations and notify observers.
    // didSet keeps UserDefaults in sync for persistence across launches.
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "sunshift.hasCompletedOnboarding") {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "sunshift.hasCompletedOnboarding")
        }
    }
}
