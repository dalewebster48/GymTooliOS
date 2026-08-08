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
    func didTapAddSet(exerciseId: String)
    func didUpdateCalories(_ text: String)
    func didUpdateReps(_ text: String, setId: String, exerciseId: String)
    func didUpdateWeight(_ text: String, setId: String, exerciseId: String)
    func didDeleteSet(setId: String, exerciseId: String)
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

    func didTapAddSet(exerciseId: String) {
        exercise(id: exerciseId)?.addSet()
    }

    func didUpdateCalories(_ text: String) {
        caloriesText = text
        caloriesBurnt = Int(text.trimmed)
    }

    func didUpdateReps(_ text: String, setId: String, exerciseId: String) {
        exercise(id: exerciseId)?.updateReps(text, setId: setId)
    }

    func didUpdateWeight(_ text: String, setId: String, exerciseId: String) {
        exercise(id: exerciseId)?.updateWeight(text, setId: setId)
    }

    func didDeleteSet(setId: String, exerciseId: String) {
        exercise(id: exerciseId)?.removeSet(id: setId)
    }

    private func exercise(id: String) -> (any LogWorkoutExerciseViewModelProtocol)? {
        exerciseViewModels.first { $0.exerciseId == id }
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
