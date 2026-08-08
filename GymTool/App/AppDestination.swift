import Foundation

enum NavigationRoute {
    case exerciseList
    case exerciseForm(mode: ExerciseFormMode, onSave: () -> Void)
    case workoutForm(mode: WorkoutFormMode, onSave: () -> Void)
    case logWorkout(workoutId: String)
    case historyDetail(entryId: String)
}

enum NavigationAction {
    case modal(NavigationRoute)
    case push(NavigationRoute)
    case bottomSheet(NavigationRoute)
}
