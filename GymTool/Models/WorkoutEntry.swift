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
}
