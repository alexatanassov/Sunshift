import Foundation
import UserNotifications

@Observable
final class NotificationPermissionService {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init() {
        Task { await refreshStatus() }
    }

    @MainActor
    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // Routine notification scheduling is handled in the notification scheduling stage.
    @MainActor
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            authorizationStatus = granted ? .authorized : .denied
        } catch {
            authorizationStatus = .denied
        }
    }
}
