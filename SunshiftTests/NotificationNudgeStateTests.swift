import Testing
import UserNotifications
@testable import Sunshift

struct NotificationNudgeStateTests {

    @Test func hiddenWhenNotificationsAuthorized() {
        let state = NotificationNudgeState(notificationStatus: .authorized, isAlarmKitAuthorized: false)
        #expect(state == .hidden)
    }

    @Test func hiddenWhenNotificationsProvisional() {
        let state = NotificationNudgeState(notificationStatus: .provisional, isAlarmKitAuthorized: false)
        #expect(state == .hidden)
    }

    @Test func hiddenWhenAlarmKitAuthorizedEvenIfNotificationsAreNot() {
        let state = NotificationNudgeState(notificationStatus: .notDetermined, isAlarmKitAuthorized: true)
        #expect(state == .hidden)
    }

    @Test func promptToEnableWhenNotDetermined() {
        let state = NotificationNudgeState(notificationStatus: .notDetermined, isAlarmKitAuthorized: false)
        #expect(state == .promptToEnable)
    }

    @Test func deniedInSettingsWhenNotificationsDeniedAndAlarmKitNotAuthorized() {
        let state = NotificationNudgeState(notificationStatus: .denied, isAlarmKitAuthorized: false)
        #expect(state == .deniedInSettings)
    }
}
