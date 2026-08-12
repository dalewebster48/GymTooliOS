import Foundation

protocol HealthService: AnyObject {
    var isAvailable: Bool { get }

    /// Finds the Apple Health workout for a session that began at `start`,
    /// prompting for access first. Returns `nil` when nothing matches — which,
    /// because HealthKit never discloses read permission, is indistinguishable
    /// from access having been declined.
    func fetchWorkout(startingAt start: Date) async throws -> HealthWorkout?
}

final class HealthServiceImpl: HealthService {
    private let healthRepository: any HealthRepository

    init(healthRepository: any HealthRepository) {
        self.healthRepository = healthRepository
    }

    var isAvailable: Bool {
        healthRepository.isAvailable
    }

    func fetchWorkout(startingAt start: Date) async throws -> HealthWorkout? {
        try await healthRepository.requestAuthorization()
        return try await healthRepository.fetchWorkout(startingAt: start)
    }
}
