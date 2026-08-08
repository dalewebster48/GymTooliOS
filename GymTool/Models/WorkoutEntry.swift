import Foundation

struct WorkoutEntry: Identifiable, Codable, Equatable {
    let id: String
    let workoutId: String
    let performedAt: Date
    let caloriesBurnt: Int?
    let exerciseEntries: [ExerciseEntry]
}

/// The sets performed against a single exercise within a `WorkoutEntry`.
/// This is a grouping rather than an entity of its own — it is identified by
/// the exercise it belongs to, which is what lets it be reconstructed by
/// grouping rows back out of the flat `entry_sets` table.
struct ExerciseEntry: Identifiable, Codable, Equatable {
    var id: String { exerciseId }

    let exerciseId: String
    let sets: [WorkoutSet]
}

struct WorkoutSet: Identifiable, Codable, Equatable {
    let id: String
    let reps: Int
    let weight: Double
}
