import Foundation

// Single source of truth for subscription entitlements.
// isPlusUser is toggled directly during development; replace with real StoreKit 2
// entitlement checks when in-app purchases are implemented.
@Observable
final class SubscriptionService {

    // MARK: - Tier

    var tier: SubscriptionTier = .free

    // Development toggle — flip to test Plus-gated UI without a real purchase.
    var isPlusUser: Bool {
        get { tier == .plus }
        set { tier = newValue ? .plus : .free }
    }

    // MARK: - Feature gates

    // Whether the user may create more than one routine (free limit: 1).
    var canCreateMoreThanOneRoutine: Bool { isPlusUser }

    // Whether the user may use fine-grained offset presets (5 min, 10 min, 60 min).
    // Free users get At event / 15 min / 30 min only.
    var canUseAdvancedOffsets: Bool { isPlusUser }

    // Whether the user may save more than one non-current location.
    var canUseSavedLocations: Bool { isPlusUser }

    // Whether the user may anchor routines to advanced light events
    // (blue hour, civil twilight, first/last light).
    var canUseAdvancedEvents: Bool { isPlusUser }

    // Whether the user may edit the notification message on a routine.
    var canUseCustomNotificationMessages: Bool { isPlusUser }

    // Whether the user may use WidgetKit home screen widgets (post-Stage 9).
    var canUseWidgets: Bool { isPlusUser }

    // Whether the user may view the 7-day solar preview (post-Stage 8).
    var canUse7DayPreview: Bool { isPlusUser }

    // Whether the user may save an additional non-current location.
    // Pass the current count of non-current saved locations.
    func canAddSavedLocation(currentNonCurrentCount: Int) -> Bool {
        if isPlusUser { return true }
        return currentNonCurrentCount < FreeTierLimits.maxSavedLocations
    }

    // Whether the user may select and use the given routine template.
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
