import Foundation

enum HealthError: Error {
    /// HealthKit isn't present on this device.
    case unavailable
}

protocol HealthRepository: AnyObject {
    var isAvailable: Bool { get }

    /// Prompts for read access. HealthKit never reports whether read access was
    /// granted, so this completing successfully does not mean data will follow.
    func requestAuthorization() async throws

    /// The workout recorded in the window starting at `start`, if there is one.
    func fetchWorkout(startingAt start: Date) async throws -> HealthWorkout?
}
