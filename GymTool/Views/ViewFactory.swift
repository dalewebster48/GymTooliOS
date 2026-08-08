import SwiftUI

/// Turns a `NavigationRoute` into the screen it describes. The direct heir to
/// `ViewControllerFactory` — it holds the `ViewModelFactory` and nothing else.
@MainActor
final class ViewFactory {
    private let viewModelFactory: ViewModelFactory

    init(viewModelFactory: ViewModelFactory) {
        self.viewModelFactory = viewModelFactory
    }

    // The home container and its two pages take their view models rather than
    // making them. Those view models live for as long as the app does and are
    // owned by `AppContext`; only the routed screens below get a view model
    // minted per presentation.

    func makeHomeContainerView(
        viewModel: any HomeContainerViewModelProtocol
    ) -> HomeContainerView {
        HomeContainerView(viewModel: viewModel, viewFactory: self)
    }

    func makeWorkoutListView(
        viewModel: any WorkoutListViewModelProtocol
    ) -> WorkoutListView {
        WorkoutListView(viewModel: viewModel)
    }

    func makeHistoryListView(
        viewModel: any HistoryListViewModelProtocol
    ) -> HistoryListView {
        HistoryListView(viewModel: viewModel)
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
