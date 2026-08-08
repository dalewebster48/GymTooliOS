import UIKit

final class ViewControllerFactory {
    private let viewModelFactory: ViewModelFactory

    init(viewModelFactory: ViewModelFactory) {
        self.viewModelFactory = viewModelFactory
    }

    func makeHomeContainerViewController() -> HomeContainerViewController {
        let viewModel = viewModelFactory.makeHomeContainerViewModel()
        return HomeContainerViewController(
            viewModel: viewModel,
            pages: [
                makeWorkoutListViewController(),
                makeHistoryListViewController()
            ]
        )
    }

    func makeWorkoutListViewController() -> WorkoutListViewController {
        let viewModel = viewModelFactory.makeWorkoutListViewModel()
        return WorkoutListViewController(viewModel: viewModel)
    }

    func makeHistoryListViewController() -> HistoryListViewController {
        let viewModel = viewModelFactory.makeHistoryListViewModel()
        return HistoryListViewController(viewModel: viewModel)
    }

    func makeHistoryDetailViewController(entryId: String) -> HistoryDetailViewController {
        let viewModel = viewModelFactory.makeHistoryDetailViewModel(entryId: entryId)
        return HistoryDetailViewController(viewModel: viewModel)
    }

    func makeExerciseListViewController() -> ExerciseListViewController {
        let viewModel = viewModelFactory.makeExerciseListViewModel()
        return ExerciseListViewController(viewModel: viewModel)
    }

    func makeExerciseFormViewController(
        mode: ExerciseFormMode,
        onSave: @escaping () -> Void
    ) -> ExerciseFormViewController {
        let viewModel = viewModelFactory.makeExerciseFormViewModel(mode: mode, onSave: onSave)
        return ExerciseFormViewController(viewModel: viewModel)
    }

    func makeWorkoutFormViewController(
        mode: WorkoutFormMode,
        onSave: @escaping () -> Void
    ) -> WorkoutFormViewController {
        let viewModel = viewModelFactory.makeWorkoutFormViewModel(mode: mode, onSave: onSave)
        return WorkoutFormViewController(viewModel: viewModel)
    }

    func makeLogWorkoutViewController(workoutId: String) -> LogWorkoutViewController {
        let viewModel = viewModelFactory.makeLogWorkoutViewModel(workoutId: workoutId)
        return LogWorkoutViewController(viewModel: viewModel)
    }
}
