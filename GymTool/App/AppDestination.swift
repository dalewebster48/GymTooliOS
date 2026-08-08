import Foundation

enum AppTab: Int, CaseIterable, Hashable {
    case workouts
    case exercises
    case insights

    var title: String {
        switch self {
        case .workouts: "Workouts"
        case .exercises: "Exercises"
        case .insights: "Insights"
        }
    }

    var systemImage: String {
        switch self {
        case .workouts: "dumbbell"
        case .exercises: "figure.strengthtraining.traditional"
        case .insights: "chart.bar"
        }
    }
}

enum NavigationRoute: Hashable, Identifiable {
    case workoutDetail(workoutId: String)
    case exerciseDetail(exerciseId: String)
    case historyDetail(entryId: String)
    case workoutForm(mode: WorkoutFormMode)
    case exerciseForm(mode: ExerciseFormMode)
    case logWorkout(workoutId: String)

    /// For `.sheet(item:)`. A route fully describes its screen, so it is its
    /// own identity.
    var id: Self { self }
}

enum NavigationAction: Hashable {
    case modal(NavigationRoute)
    case push(NavigationRoute)
}
