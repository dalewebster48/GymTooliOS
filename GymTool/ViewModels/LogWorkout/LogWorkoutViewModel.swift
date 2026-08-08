import Foundation
import Observation

/// Vends the per-exercise child view models for the logging screen. Declared
/// here and conformed by `ViewModelFactory` so the parent view model never
/// constructs a child itself.
@MainActor
protocol LogWorkoutExerciseViewModelFactory: AnyObject {
    func makeLogWorkoutExerciseViewModel(exercise: Exercise) -> any LogWorkoutExerciseViewModelProtocol
}

@MainActor
protocol LogWorkoutViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var exerciseViewModels: [any LogWorkoutExerciseViewModelProtocol] { get }
    var canSubmit: Bool { get }
    var errorMessage: String? { get }
    var caloriesText: String { get }

    func onAppear()
    func didTapAddSet(inExerciseAt exerciseIndex: Int)
    func didUpdateCalories(_ text: String)
    func didUpdateReps(_ text: String, setIndex: Int, exerciseIndex: Int)
    func didUpdateWeight(_ text: String, setIndex: Int, exerciseIndex: Int)
    func didDeleteSet(setIndex: Int, exerciseIndex: Int)
    func didTapSubmit()
    func didTapCancel()
}

@Observable
@MainActor
final class LogWorkoutViewModel: LogWorkoutViewModelProtocol {
    @ObservationIgnored private let workoutId: String
    @ObservationIgnored private let workoutService: any WorkoutService
    @ObservationIgnored private let workoutEntryService: any WorkoutEntryService
    @ObservationIgnored private let exerciseViewModelFactory: any LogWorkoutExerciseViewModelFactory
    @ObservationIgnored private let navigator: any Navigator

    var title = "Log Workout"
    var exerciseViewModels: [any LogWorkoutExerciseViewModelProtocol] = []
    var errorMessage: String?
    var caloriesText = ""

    /// Optional, and deliberately not part of `canSubmit` — a session is worth
    /// recording whether or not you bothered to enter calories.
    @ObservationIgnored private var caloriesBurnt: Int?

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

    func onAppear() {
        guard exerciseViewModels.isEmpty else { return }
        loadWorkout()
    }

    func didTapAddSet(inExerciseAt exerciseIndex: Int) {
        guard let exerciseViewModel = exerciseViewModels[safe: exerciseIndex] else { return }
        exerciseViewModel.addSet()
    }

    func didUpdateCalories(_ text: String) {
        caloriesText = text
        caloriesBurnt = Int(text.trimmed)
    }

    func didUpdateReps(_ text: String, setIndex: Int, exerciseIndex: Int) {
        guard let exerciseViewModel = exerciseViewModels[safe: exerciseIndex] else { return }
        exerciseViewModel.updateReps(text, at: setIndex)
    }

    func didUpdateWeight(_ text: String, setIndex: Int, exerciseIndex: Int) {
        guard let exerciseViewModel = exerciseViewModels[safe: exerciseIndex] else { return }
        exerciseViewModel.updateWeight(text, at: setIndex)
    }

    func didDeleteSet(setIndex: Int, exerciseIndex: Int) {
        guard let exerciseViewModel = exerciseViewModels[safe: exerciseIndex] else { return }
        exerciseViewModel.removeSet(at: setIndex)
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
}
