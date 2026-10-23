import Foundation
import UserNotifications

final class UserNotificationRepository: NSObject, NotificationRepository {
    weak var delegate: (any NotificationRepositoryDelegate)?

    private let center: UNUserNotificationCenter

    /// Becomes the center's delegate on creation. That has to happen before
    /// launch finishes, or a tap that cold-launches the app is never reported —
    /// which holds because `AppContext` is built in the `App` initialiser.
    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func schedule(
        id: String,
        title: String,
        body: String,
        after delay: TimeInterval
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension UserNotificationRepository: UNUserNotificationCenterDelegate {
    /// Without this, iOS drops notifications that arrive while the app is open.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let id = response.notification.request.identifier
        await MainActor.run {
            delegate?.notificationRepository(self, didOpenNotificationWithId: id)
        }
    }
}
