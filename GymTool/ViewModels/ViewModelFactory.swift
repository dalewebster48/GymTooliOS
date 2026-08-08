import Foundation

final class ViewModelFactory {
    private let services: ServicesContainer
    private let navigator: any Navigator

    init(
        services: ServicesContainer,
        navigator: any Navigator
    ) {
        self.services = services
        self.navigator = navigator
    }

    func makeHomeContainerViewModel() -> any HomeContainerViewModelProtocol {
        HomeContainerViewModel()
    }

    func makeWorkoutListViewModel() -> any WorkoutListViewModelProtocol {
        WorkoutListViewModel(
            workoutService: services.workoutService,
            navigator: navigator
        )
    }

    func makeHistoryListViewModel() -> any HistoryListViewModelProtocol {
        HistoryListViewModel(
            workoutEntryService: services.workoutEntryService,
            navigator: navigator
        )
    }

    func makeHistoryDetailViewModel(entryId: String) -> any HistoryDetailViewModelProtocol {
        HistoryDetailViewModel(
            entryId: entryId,
            workoutEntryService: services.workoutEntryService
        )
    }

    func makeExerciseListViewModel() -> any ExerciseListViewModelProtocol {
        ExerciseListViewModel(
            exerciseService: services.exerciseService,
            navigator: navigator
        )
    }

    func makeExerciseFormViewModel(
        mode: ExerciseFormMode,
        onSave: @escaping () -> Void
    ) -> any ExerciseFormViewModelProtocol {
        ExerciseFormViewModel(
            mode: mode,
            exerciseService: services.exerciseService,
            navigator: navigator,
            onSave: onSave
        )
    }

    func makeWorkoutFormViewModel(
        mode: WorkoutFormMode,
        onSave: @escaping () -> Void
    ) -> any WorkoutFormViewModelProtocol {
        WorkoutFormViewModel(
            mode: mode,
            exerciseService: services.exerciseService,
            workoutService: services.workoutService,
            navigator: navigator,
            onSave: onSave
        )
    }

    func makeLogWorkoutViewModel(workoutId: String) -> any LogWorkoutViewModelProtocol {
        LogWorkoutViewModel(
            workoutId: workoutId,
            workoutService: services.workoutService,
            workoutEntryService: services.workoutEntryService,
            exerciseViewModelFactory: self,
            navigator: navigator
        )
    }
}

// MARK: - LogWorkoutExerciseViewModelFactory

extension ViewModelFactory: LogWorkoutExerciseViewModelFactory {
    func makeLogWorkoutExerciseViewModel(exercise: Exercise) -> any LogWorkoutExerciseViewModelProtocol {
        LogWorkoutExerciseViewModel(exercise: exercise)
    }
}
