import Foundation

@MainActor
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
        HomeContainerViewModel(childViewModelFactory: self)
    }

    func makeWorkoutDetailViewModel(workoutId: String) -> any WorkoutDetailViewModelProtocol {
        WorkoutDetailViewModel(
            workoutId: workoutId,
            workoutService: services.workoutService,
            navigator: navigator
        )
    }

    func makeExerciseDetailViewModel(exerciseId: String) -> any ExerciseDetailViewModelProtocol {
        ExerciseDetailViewModel(
            exerciseId: exerciseId,
            exerciseService: services.exerciseService,
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

    func makeExerciseFormViewModel(mode: ExerciseFormMode) -> any ExerciseFormViewModelProtocol {
        ExerciseFormViewModel(
            mode: mode,
            exerciseService: services.exerciseService,
            navigator: navigator
        )
    }

    func makeWorkoutFormViewModel(mode: WorkoutFormMode) -> any WorkoutFormViewModelProtocol {
        WorkoutFormViewModel(
            mode: mode,
            exerciseService: services.exerciseService,
            workoutService: services.workoutService,
            navigator: navigator
        )
    }

    func makeLogWorkoutViewModel(workoutId: String) -> any LogWorkoutViewModelProtocol {
        LogWorkoutViewModel(
            workoutId: workoutId,
            workoutSessionService: services.workoutSessionService,
            navigator: navigator
        )
    }

    func makeRecordExerciseViewModel(exerciseId: String) -> any RecordExerciseViewModelProtocol {
        RecordExerciseViewModel(
            exerciseId: exerciseId,
            workoutSessionService: services.workoutSessionService,
            workoutEntryService: services.workoutEntryService
        )
    }
}

// MARK: - HomeContainerChildViewModelFactory

extension ViewModelFactory: HomeContainerChildViewModelFactory {
    func makeWorkoutListViewModel() -> any WorkoutListViewModelProtocol {
        WorkoutListViewModel(
            workoutService: services.workoutService,
            exerciseService: services.exerciseService,
            navigator: navigator
        )
    }

    func makeExerciseListViewModel() -> any ExerciseListViewModelProtocol {
        ExerciseListViewModel(
            exerciseService: services.exerciseService,
            navigator: navigator
        )
    }

    func makeHistoryListViewModel() -> any HistoryListViewModelProtocol {
        HistoryListViewModel(
            workoutEntryService: services.workoutEntryService,
            workoutSessionService: services.workoutSessionService,
            navigator: navigator
        )
    }
}
