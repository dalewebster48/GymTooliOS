import Foundation

enum NavigationRoute: Hashable {
    case exerciseList
    case exerciseForm(mode: ExerciseFormMode)
    case workoutForm(mode: WorkoutFormMode)
    case logWorkout(workoutId: String)
    case historyDetail(entryId: String)
}

enum NavigationAction: Hashable {
    case modal(NavigationRoute)
    case push(NavigationRoute)
}
