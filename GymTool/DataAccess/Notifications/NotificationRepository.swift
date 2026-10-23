import Foundation

protocol NotificationRepositoryDelegate: AnyObject {
    /// The user tapped a delivered notification, identified by the `id` it was
    /// scheduled with.
    func notificationRepository(
        _ notificationRepository: any NotificationRepository,
        didOpenNotificationWithId id: String
    )
}

protocol NotificationRepository: AnyObject {
    var delegate: (any NotificationRepositoryDelegate)? { get set }

    /// Prompts for permission to show alerts. Returns whether it was granted;
    /// once answered, iOS returns the stored answer without prompting again.
    func requestAuthorization() async throws -> Bool

    /// Schedules a one-off notification. Scheduling again with the same `id`
    /// replaces the pending one.
    func schedule(
        id: String,
        title: String,
        body: String,
        after delay: TimeInterval
    ) async throws

    func cancel(id: String)
}
