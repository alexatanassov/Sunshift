import Foundation

// Mock subscription service — replace isPlusUser with real StoreKit entitlement check
// when in-app purchases are implemented.
@Observable
final class SubscriptionService {

    // MARK: - Tier

    var tier: SubscriptionTier = .free

    // Toggle this during development to test Plus-gated UI without a real purchase.
    var isPlusUser: Bool {
        get { tier == .plus }
        set { tier = newValue ? .plus : .free }
    }

    // MARK: - Feature gates

    var canCreateMoreThanOneRoutine: Bool { isPlusUser }
    var canUseCustomOffsets: Bool { isPlusUser }
    var canUseSavedLocations: Bool { isPlusUser }
    var canUseAdvancedEvents: Bool { isPlusUser }
    var canUseCustomNotificationMessages: Bool { isPlusUser }
    var canUseWidgets: Bool { isPlusUser }
    var canUse7DayPreview: Bool { isPlusUser }

    func canUseTemplate(_ template: RoutineTemplate) -> Bool {
        !template.requiresPlus || isPlusUser
    }

    // MARK: - StoreKit stubs (replace with real implementation)

    func purchase() async throws {
        // TODO: StoreKit 2 purchase flow
    }

    func restorePurchases() async throws {
        // TODO: StoreKit 2 restore flow
    }
}
