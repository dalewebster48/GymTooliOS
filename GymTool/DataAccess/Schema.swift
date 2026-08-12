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
    /// Written by the Apple Health sync rather than entered by hand.
    static let caloriesBurnt = SQLite.Expression<Int?>("calories_burnt")

    // Added in schema version 1. Optional because `addColumn` on an existing
    // table can't back-fill from another column, and rows logged before the
    // sync existed have nothing meaningful to put here.

    /// When the session was started, as opposed to when it was submitted. This
    /// is the anchor for the Health workout search window.
    static let startedAt = SQLite.Expression<Date?>("started_at")
    /// The `HKWorkout` UUID. Non-nil means this session has been linked.
    static let healthWorkoutId = SQLite.Expression<String?>("health_workout_id")
    static let averageHeartRate = SQLite.Expression<Double?>("average_heart_rate")
    /// Seconds, from the linked Health workout.
    static let duration = SQLite.Expression<Double?>("duration")
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
