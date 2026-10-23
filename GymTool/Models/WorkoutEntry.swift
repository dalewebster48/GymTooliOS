import Foundation

struct WorkoutEntry: Identifiable, Codable, Hashable {
    let id: String
    let workoutId: String
    let performedAt: Date
    let caloriesBurnt: Int?
    let exerciseEntries: [ExerciseEntry]

    /// When recording began, as opposed to when it was submitted. Nil for
    /// sessions logged before this was captured.
    let startedAt: Date?
    /// The `HKWorkout` this session was matched to.
    let healthWorkoutId: String?
    let averageHeartRate: Double?
    let duration: TimeInterval?

    /// Free-text comment left on the session. Nil when none was written.
    let notes: String?
    /// Whether the whole workout was completed. Nil for sessions logged before
    /// this was captured — unknown, not unfinished.
    let isFinished: Bool?

    /// Linked state is the presence of the id — there is no separate flag to
    /// fall out of step with it.
    var isLinked: Bool { healthWorkoutId != nil }
}

/// The sets performed against a single exercise within a `WorkoutEntry`.
/// This is a grouping rather than an entity of its own — it is identified by
/// the exercise it belongs to, which is what lets it be reconstructed by
/// grouping rows back out of the flat `entry_sets` table.
struct ExerciseEntry: Identifiable, Codable, Hashable {
    var id: String { exerciseId }

    let exerciseId: String
    let sets: [WorkoutSet]
}

struct WorkoutSet: Identifiable, Codable, Hashable {
    let id: String
    let reps: Int
    let weight: Double
    /// When reps were first entered — the moment the set counts as done. Nil
    /// for sets logged before this was captured, and for sets not yet filled in.
    let completedAt: Date?
}

extension Array where Element == WorkoutSet {
    /// When the first set was done, i.e. when the exercise was started.
    var firstCompletedAt: Date? {
        compactMap(\.completedAt).min()
    }
}

/// The order exercises were actually performed in, which isn't necessarily
/// the order the workout lists them.
enum PerformedOrder {
    /// 1-based rank of each exercise by when it was started, keyed by exercise
    /// id. Exercises with no timestamped sets are left out, so sessions logged
    /// before timestamps existed get no order rather than a wrong one.
    static func ranks(startTimes: [(exerciseId: String, startedAt: Date?)]) -> [String: Int] {
        let timed = startTimes.compactMap { item in
            item.startedAt.map { (exerciseId: item.exerciseId, startedAt: $0) }
        }
        let sorted = timed.sorted { $0.startedAt < $1.startedAt }
        return Dictionary(
            uniqueKeysWithValues: sorted.enumerated().map { ($1.exerciseId, $0 + 1) }
        )
    }
}
