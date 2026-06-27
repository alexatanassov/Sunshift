import Testing
import Foundation
@testable import Sunshift

struct SubscriptionServiceTests {

    // MARK: - Tier

    @Test func defaultTierIsFree() {
        let svc = SubscriptionService()
        #expect(svc.tier == .free)
        #expect(!svc.isPlusUser)
    }

    @Test func toggleIsPlusUserChangesTierToPlus() {
        let svc = SubscriptionService()
        svc.isPlusUser = true
        #expect(svc.tier == .plus)
        #expect(svc.isPlusUser)
    }

    @Test func toggleIsPlusUserOffChangesTierToFree() {
        let svc = SubscriptionService()
        svc.isPlusUser = true
        svc.isPlusUser = false
        #expect(svc.tier == .free)
        #expect(!svc.isPlusUser)
    }

    // MARK: - Template gate

    @Test func canUseTemplate_sunsetWalk_freeUserAllowed() {
        let svc = SubscriptionService()
        #expect(svc.canUseTemplate(.sunsetWalk))
    }

    @Test func canUseTemplate_custom_freeUserAllowed() {
        let svc = SubscriptionService()
        #expect(svc.canUseTemplate(.custom))
    }

    @Test func canUseTemplate_morningLight_freeUserBlocked() {
        let svc = SubscriptionService()
        #expect(!svc.canUseTemplate(.morningLight))
    }

    @Test func canUseTemplate_windDown_freeUserBlocked() {
        let svc = SubscriptionService()
        #expect(!svc.canUseTemplate(.windDown))
    }

    @Test func canUseTemplate_goldenHourShoot_freeUserBlocked() {
        let svc = SubscriptionService()
        #expect(!svc.canUseTemplate(.goldenHourShoot))
    }

    @Test func canUseTemplate_allTemplates_plusUserAllowed() {
        let svc = SubscriptionService()
        svc.isPlusUser = true
        for template in RoutineTemplate.allCases {
            #expect(svc.canUseTemplate(template))
        }
    }

    // MARK: - Notification message gate

    @Test func canUseCustomNotificationMessages_freeUserBlocked() {
        let svc = SubscriptionService()
        #expect(!svc.canUseCustomNotificationMessages)
    }

    @Test func canUseCustomNotificationMessages_plusUserAllowed() {
        let svc = SubscriptionService()
        svc.isPlusUser = true
        #expect(svc.canUseCustomNotificationMessages)
    }

    // MARK: - Advanced offsets gate

    @Test func canUseAdvancedOffsets_freeUserBlocked() {
        let svc = SubscriptionService()
        #expect(!svc.canUseAdvancedOffsets)
    }

    @Test func canUseAdvancedOffsets_plusUserAllowed() {
        let svc = SubscriptionService()
        svc.isPlusUser = true
        #expect(svc.canUseAdvancedOffsets)
    }

    // MARK: - Saved location gate

    @Test func canAddSavedLocation_freeUserBelowLimit_allowed() {
        let svc = SubscriptionService()
        #expect(svc.canAddSavedLocation(currentNonCurrentCount: 0))
    }

    @Test func canAddSavedLocation_freeUserAtLimit_blocked() {
        let svc = SubscriptionService()
        #expect(!svc.canAddSavedLocation(currentNonCurrentCount: FreeTierLimits.maxSavedLocations))
    }

    @Test func canAddSavedLocation_plusUserBeyondLimit_allowed() {
        let svc = SubscriptionService()
        svc.isPlusUser = true
        #expect(svc.canAddSavedLocation(currentNonCurrentCount: 100))
    }

    // MARK: - Routine count gate

    @Test func canCreateMoreThanOneRoutine_freeUserBlocked() {
        let svc = SubscriptionService()
        #expect(!svc.canCreateMoreThanOneRoutine)
    }

    @Test func canCreateMoreThanOneRoutine_plusUserAllowed() {
        let svc = SubscriptionService()
        svc.isPlusUser = true
        #expect(svc.canCreateMoreThanOneRoutine)
    }
}
