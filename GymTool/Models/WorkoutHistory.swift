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
}

struct WorkoutHistoryDetail: Identifiable, Hashable {
    var id: String { entryId }

    let entryId: String
    let workoutName: String
    let performedAt: Date
    let caloriesBurnt: Int?
    let exercises: [LoggedExercise]
}

struct LoggedExercise: Identifiable, Hashable {
    var id: String { exerciseId }

    let exerciseId: String
    let name: String
    let sets: [WorkoutSet]
}
