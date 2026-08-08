import SwiftUI

/// Turns a `NavigationRoute` into the screen it describes. The direct heir to
/// `ViewControllerFactory` — it holds the `ViewModelFactory` and nothing else.
@MainActor
final class ViewFactory {
    private let viewModelFactory: ViewModelFactory

    init(viewModelFactory: ViewModelFactory) {
        self.viewModelFactory = viewModelFactory
    }

    func makeHomeContainerView() -> HomeContainerView {
        HomeContainerView(viewModel: viewModelFactory.makeHomeContainerViewModel())
    }

    /// `@ViewBuilder` lets the switch return different concrete view types
    /// without boxing each one in `AnyView`.
    @ViewBuilder
    func view(for route: NavigationRoute) -> some View {
        switch route {
        case .exerciseList:
            ExerciseListView(viewModel: viewModelFactory.makeExerciseListViewModel())

        case .exerciseForm(let mode):
            ExerciseFormView(viewModel: viewModelFactory.makeExerciseFormViewModel(mode: mode))

        case .workoutForm(let mode):
            WorkoutFormView(viewModel: viewModelFactory.makeWorkoutFormViewModel(mode: mode))

        case .logWorkout(let workoutId):
            LogWorkoutView(viewModel: viewModelFactory.makeLogWorkoutViewModel(workoutId: workoutId))

        case .historyDetail(let entryId):
            HistoryDetailView(viewModel: viewModelFactory.makeHistoryDetailViewModel(entryId: entryId))
        }
    }
}
