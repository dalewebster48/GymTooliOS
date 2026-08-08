import Foundation
import SQLite

// `Foundation.Expression` collides with SQLite.swift's `Expression` on this
// deployment target, so every column is fully qualified as `SQLite.Expression`.

enum ExerciseTable {
    static let table = Table("exercises")
    static let id = SQLite.Expression<String>("id")
    static let name = SQLite.Expression<String>("name")
    static let details = SQLite.Expression<String>("details")
}

enum WorkoutTable {
    static let table = Table("workouts")
    static let id = SQLite.Expression<String>("id")
    static let name = SQLite.Expression<String>("name")
}

enum WorkoutExerciseTable {
    static let table = Table("workout_exercises")
    static let workoutId = SQLite.Expression<String>("workout_id")
    static let exerciseId = SQLite.Expression<String>("exercise_id")
    /// Ordering of the exercise within its workout.
    static let position = SQLite.Expression<Int>("position")
}

enum WorkoutEntryTable {
    static let table = Table("workout_entries")
    static let id = SQLite.Expression<String>("id")
    static let workoutId = SQLite.Expression<String>("workout_id")
    static let performedAt = SQLite.Expression<Date>("performed_at")
    /// Optional — logging a session without entering calories is allowed.
    static let caloriesBurnt = SQLite.Expression<Int?>("calories_burnt")
}

enum EntrySetTable {
    static let table = Table("entry_sets")
    static let id = SQLite.Expression<String>("id")
    static let entryId = SQLite.Expression<String>("entry_id")
    /// Intentionally not a cascading foreign key to `exercises`: deleting an
    /// exercise must not rewrite history you already logged against it.
    static let exerciseId = SQLite.Expression<String>("exercise_id")
    /// Ordinal of the set across the *whole* entry, not just within its
    /// exercise. Reading rows back in `position` order therefore restores both
    /// the exercise ordering and the set ordering in a single pass.
    static let position = SQLite.Expression<Int>("position")
    static let reps = SQLite.Expression<Int>("reps")
    static let weight = SQLite.Expression<Double>("weight")
}
