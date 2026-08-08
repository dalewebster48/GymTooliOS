import Foundation

/// Vends the per-exercise child view models for the logging screen. Declared
/// here and conformed by `ViewModelFactory` so the parent view model never
/// constructs a child itself.
protocol LogWorkoutExerciseViewModelFactory: AnyObject {
    func makeLogWorkoutExerciseViewModel(exercise: Exercise) -> any LogWorkoutExerciseViewModelProtocol
}

protocol LogWorkoutViewModelProtocol: AnyObject {
    var title: String { get }
    var exerciseViewModels: [any LogWorkoutExerciseViewModelProtocol] { get }
    var canSubmit: Bool { get }
    var errorMessage: String? { get }
    /// Bumped whenever sets are added or removed. The view controller reloads
    /// its table only when this changes, so typing in a field never tears down
    /// the text field being edited.
    var setsVersion: Int { get }
    var viewDelegate: (any LogWorkoutViewModelViewDelegate)? { get set }

    func didTapAddSet(inExerciseAt exerciseIndex: Int)
    func didUpdateCalories(_ text: String)
    func didUpdateReps(_ text: String, setIndex: Int, exerciseIndex: Int)
    func didUpdateWeight(_ text: String, setIndex: Int, exerciseIndex: Int)
    func didDeleteSet(setIndex: Int, exerciseIndex: Int)
    func didTapSubmit()
    func didTapCancel()
}

protocol LogWorkoutViewModelViewDelegate: AnyObject {
    func bind(viewModel: any LogWorkoutViewModelProtocol)
}

final class LogWorkoutViewModel: LogWorkoutViewModelProtocol {
    private let workoutId: String
    private let workoutService: any WorkoutService
    private let workoutEntryService: any WorkoutEntryService
    private let exerciseViewModelFactory: any LogWorkoutExerciseViewModelFactory
    private let navigator: any Navigator

    weak var viewDelegate: (any LogWorkoutViewModelViewDelegate)? {
        didSet { loadWorkout() }
    }

    var title = "Log Workout" {
        didSet { bind() }
    }

    var exerciseViewModels: [any LogWorkoutExerciseViewModelProtocol] = [] {
        didSet {
            setsVersion += 1
        }
    }

    var setsVersion = 0 {
        didSet { bind() }
    }

    var errorMessage: String? {
        didSet { bind() }
    }

    /// Optional, and deliberately not part of `canSubmit` — a session is worth
    /// recording whether or not you bothered to enter calories.
    private var caloriesBurnt: Int?

    var canSubmit: Bool {
        exerciseViewModels.contains { $0.makeExerciseEntry() != nil }
    }

    init(
        workoutId: String,
        workoutService: any WorkoutService,
        workoutEntryService: any WorkoutEntryService,
        exerciseViewModelFactory: any LogWorkoutExerciseViewModelFactory,
        navigator: any Navigator
    ) {
        self.workoutId = workoutId
        self.workoutService = workoutService
        self.workoutEntryService = workoutEntryService
        self.exerciseViewModelFactory = exerciseViewModelFactory
        self.navigator = navigator
    }

    func didTapAddSet(inExerciseAt exerciseIndex: Int) {
        guard let exerciseViewModel = exerciseViewModels[safe: exerciseIndex] else { return }
        exerciseViewModel.addSet()
        setsVersion += 1
    }

    func didUpdateCalories(_ text: String) {
        caloriesBurnt = Int(text.trimmed)
    }

    func didUpdateReps(_ text: String, setIndex: Int, exerciseIndex: Int) {
        guard let exerciseViewModel = exerciseViewModels[safe: exerciseIndex] else { return }
        exerciseViewModel.updateReps(text, at: setIndex)
        // Deliberately no `setsVersion` bump: the set structure is unchanged,
        // and rebuilding the table here would end editing on every keystroke.
        bind()
    }

    func didUpdateWeight(_ text: String, setIndex: Int, exerciseIndex: Int) {
        guard let exerciseViewModel = exerciseViewModels[safe: exerciseIndex] else { return }
        exerciseViewModel.updateWeight(text, at: setIndex)
        bind()
    }

    func didDeleteSet(setIndex: Int, exerciseIndex: Int) {
        guard let exerciseViewModel = exerciseViewModels[safe: exerciseIndex] else { return }
        exerciseViewModel.removeSet(at: setIndex)
        setsVersion += 1
    }

    func didTapSubmit() {
        let entries = exerciseViewModels.compactMap { $0.makeExerciseEntry() }
        guard !entries.isEmpty else { return }

        do {
            try workoutEntryService.logWorkout(
                workoutId: workoutId,
                exerciseEntries: entries,
                caloriesBurnt: caloriesBurnt
            )
            navigator.dismiss()
        } catch {
            errorMessage = "Couldn't save this workout. \(error.localizedDescription)"
        }
    }

    func didTapCancel() {
        navigator.dismiss()
    }

    private func loadWorkout() {
        do {
            guard let workout = try workoutService.fetchWorkout(id: workoutId) else {
                errorMessage = "That workout no longer exists."
                return
            }
            title = workout.name
            exerciseViewModels = workout.exercises.map {
                exerciseViewModelFactory.makeLogWorkoutExerciseViewModel(exercise: $0)
            }
        } catch {
            errorMessage = "Couldn't load this workout. \(error.localizedDescription)"
        }
    }

    private func bind() {
        Task { @MainActor in
            viewDelegate?.bind(viewModel: self)
        }
    }
}
