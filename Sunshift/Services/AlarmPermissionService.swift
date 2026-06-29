import Foundation
import AlarmKit

@available(iOS 26.0, *)
@available(macCatalyst, unavailable)
@Observable
final class AlarmPermissionService {
    private(set) var authorizationState: AlarmManager.AuthorizationState = .notDetermined

    init() {
        authorizationState = AlarmManager.shared.authorizationState
        Task { await observeAuthorizationUpdates() }
    }

    func requestPermission() async {
        if let state = try? await AlarmManager.shared.requestAuthorization() {
            authorizationState = state
        }
    }

    private func observeAuthorizationUpdates() async {
        for await state in AlarmManager.shared.authorizationUpdates {
            authorizationState = state
        }
    }
}
