import Foundation

/// Stores the in-progress session as JSON in `UserDefaults`. It is a single
/// small record that has to survive the app being killed, which is exactly what
/// `UserDefaults` is for — the SQLite store is for finished sessions.
final class UserDefaultsWorkoutSessionRepository: WorkoutSessionRepository {
    private static let key = "com.gymtool.workoutSession"

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetch() throws -> WorkoutSession? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try decoder.decode(WorkoutSession.self, from: data)
    }

    func save(_ session: WorkoutSession) throws {
        let data = try encoder.encode(session)
        defaults.set(data, forKey: Self.key)
    }

    func clear() throws {
        defaults.removeObject(forKey: Self.key)
    }
}
