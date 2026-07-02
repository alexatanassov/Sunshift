import Foundation
import UserNotifications

/// Determines whether the "turn on alerts" nudge card should be shown, and what
/// it should say, based on current notification and AlarmKit authorization state.
enum NotificationNudgeState: Equatable {
    /// Notifications (or AlarmKit) are already authorized; nothing to show.
    case hidden
    /// Permission has not been requested yet, or was denied only provisionally
    /// (e.g. .notDetermined); tapping the card's button should request permission.
    case promptToEnable
    /// Permission was explicitly denied at the system level; the card should
    /// point the user to Settings instead of requesting again.
    case deniedInSettings

    init(notificationStatus: UNAuthorizationStatus, isAlarmKitAuthorized: Bool) {
        if isAlarmKitAuthorized || notificationStatus == .authorized || notificationStatus == .provisional {
            self = .hidden
        } else if notificationStatus == .denied {
            self = .deniedInSettings
        } else {
            self = .promptToEnable
        }
    }
}
