import Foundation

// Logged sessions store ids, but history has to show names — including for
// records whose workout or exercise has since been deleted. These read models
// carry names already resolved, with fallbacks applied.

struct WorkoutHistoryItem: Identifiable, Hashable {
    var id: String { entryId }

    let entryId: String
    let workoutName: String
    let performedAt: Date
    let exerciseCount: Int
    let setCount: Int
    let caloriesBurnt: Int?
    let healthWorkoutId: String?
    let isFinished: Bool?

    var isLinked: Bool { healthWorkoutId != nil }
}

struct WorkoutHistoryDetail: Identifiable, Hashable {
    var id: String { entryId }

    let entryId: String
    let workoutName: String
    let performedAt: Date
    let caloriesBurnt: Int?
    let exercises: [LoggedExercise]

    /// Anchors the Apple Health search window. Falls back to `performedAt` for
    /// sessions logged before this was captured.
    let startedAt: Date?
    let healthWorkoutId: String?
    let averageHeartRate: Double?
    let duration: TimeInterval?
    let notes: String?
    let isFinished: Bool?

    var isLinked: Bool { healthWorkoutId != nil }

    var healthSearchAnchor: Date { startedAt ?? performedAt }
}

struct LoggedExercise: Identifiable, Hashable {
    var id: String { exerciseId }

    let exerciseId: String
    let name: String
    let sets: [WorkoutSet]
    /// 1-based position in the order exercises were performed. Nil when the
    /// session predates set timestamps.
    let performedOrder: Int?
}
