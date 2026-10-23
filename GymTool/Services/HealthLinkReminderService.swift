import Foundation

protocol HealthLinkReminderConsumer: AnyObject {
    /// A reminder was tapped, and the session it was for should be shown.
    func reminderWasOpened(
        healthLinkReminderService: any HealthLinkReminderService,
        entryId: String
    )
}

/// Reminds you to link a logged session to Apple Health once the Watch workout
/// has had time to land, and stands down if you link it first.
protocol HealthLinkReminderService: AnyObject {
    func scheduleReminder(entryId: String, workoutName: String)
    func cancelReminder(entryId: String)
    /// The session from a reminder tapped before anyone was listening — i.e.
    /// one that cold-launched the app. Returns it once, then nil.
    func takeOpenedEntryId() -> String?

    func addConsumer(_ consumer: any HealthLinkReminderConsumer)
    func removeConsumer(_ consumer: any HealthLinkReminderConsumer)
}

final class HealthLinkReminderServiceImpl: HealthLinkReminderService {
    private static let delay: TimeInterval = 2 * 60 * 60
    private static let title = "Link Apple Health"
    private static let idPrefix = "health-link-reminder."

    private let notificationRepository: any NotificationRepository
    private let healthService: any HealthService

    private var openedEntryId: String?

    private var _consumers: NSHashTable<AnyObject> = .weakObjects()
    private var consumers: [any HealthLinkReminderConsumer] {
        _consumers.allObjects.compactMap { $0 as? HealthLinkReminderConsumer }
    }

    init(
        notificationRepository: any NotificationRepository,
        healthService: any HealthService
    ) {
        self.notificationRepository = notificationRepository
        self.healthService = healthService

        notificationRepository.delegate = self
    }

    func scheduleReminder(entryId: String, workoutName: String) {
        // Nothing to link to on a device without Health.
        guard healthService.isAvailable else { return }

        let id = Self.notificationId(entryId: entryId)
        let body = "Head back to \(workoutName) in History and link it to pull in calories and heart rate."

        // Fire-and-forget: a reminder that couldn't be scheduled must never
        // fail the log it was attached to.
        Task { [notificationRepository] in
            guard (try? await notificationRepository.requestAuthorization()) == true else { return }
            try? await notificationRepository.schedule(
                id: id,
                title: Self.title,
                body: body,
                after: Self.delay
            )
        }
    }

    func cancelReminder(entryId: String) {
        notificationRepository.cancel(id: Self.notificationId(entryId: entryId))
    }

    func takeOpenedEntryId() -> String? {
        defer { openedEntryId = nil }
        return openedEntryId
    }

    func addConsumer(_ consumer: any HealthLinkReminderConsumer) {
        _consumers.add(consumer)
    }

    func removeConsumer(_ consumer: any HealthLinkReminderConsumer) {
        _consumers.remove(consumer)
    }

    /// One reminder per session, so linking or deleting one session can't
    /// cancel another's.
    private static func notificationId(entryId: String) -> String {
        idPrefix + entryId
    }
}

// MARK: - NotificationRepositoryDelegate

extension HealthLinkReminderServiceImpl: NotificationRepositoryDelegate {
    func notificationRepository(
        _ notificationRepository: any NotificationRepository,
        didOpenNotificationWithId id: String
    ) {
        guard id.hasPrefix(Self.idPrefix) else { return }
        let entryId = String(id.dropFirst(Self.idPrefix.count))

        // Held until taken when nobody is listening yet, so a cold launch still
        // lands on the session once the root screen appears.
        guard !consumers.isEmpty else {
            openedEntryId = entryId
            return
        }
        consumers.forEach { $0.reminderWasOpened(healthLinkReminderService: self, entryId: entryId) }
    }
}
