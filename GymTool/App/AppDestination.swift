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

    /// Whether a swipe may dismiss this screen when it is presented as a sheet.
    /// Screens holding unsaved input must be left deliberately, through Cancel
    /// or Save — a stray drag should not discard a session you just logged.
    var allowsInteractiveDismissal: Bool {
        switch self {
        case .logWorkout, .workoutForm, .exerciseForm:
            false
        case .workoutDetail, .exerciseDetail, .historyDetail:
            true
        }
    }
}

enum NavigationAction: Hashable {
    case modal(NavigationRoute)
    case push(NavigationRoute)
}
