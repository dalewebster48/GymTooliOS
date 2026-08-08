import Foundation
import Observation

@MainActor
protocol WorkoutDetailViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var exercises: [Exercise] { get }
    var exercisesSectionTitle: String { get }
    var emptyStateMessage: String { get }
    var hasExercises: Bool { get }
    var logButtonTitle: String { get }
    var deleteButtonTitle: String { get }
    var deleteConfirmationTitle: String { get }
    var deleteConfirmationMessage: String { get }
    var isConfirmingDelete: Bool { get }
    var errorMessage: String? { get }

    func onAppear()
    func detailText(for exercise: Exercise) -> String
    func didTapLogWorkout()
    func didTapEdit()
    func didTapDelete()
    func didConfirmDelete()
    func didCancelDelete()
}

@Observable
@MainActor
final class WorkoutDetailViewModel: WorkoutDetailViewModelProtocol {
    @ObservationIgnored private let workoutId: String
    @ObservationIgnored private let workoutService: any WorkoutService
    @ObservationIgnored private let navigator: any Navigator

    /// Held so Edit and Delete can act on the loaded workout rather than
    /// re-reading it.
    @ObservationIgnored private var workout: Workout?

    var title = ""
    var exercises: [Exercise] = []
    var errorMessage: String?
    var isConfirmingDelete = false

    let exercisesSectionTitle = "EXERCISES"
    let emptyStateMessage = "This workout has no exercises yet."
    let logButtonTitle = "Log Workout"
    let deleteButtonTitle = "Delete Workout"
    let deleteConfirmationTitle = "Delete this workout?"
    let deleteConfirmationMessage = "Sessions you've already logged from it are kept."

    var hasExercises: Bool {
        !exercises.isEmpty
    }

    init(
        workoutId: String,
        workoutService: any WorkoutService,
        navigator: any Navigator
    ) {
        self.workoutId = workoutId
        self.workoutService = workoutService
        self.navigator = navigator

        // Editing happens in a modal raised from this screen, so the result has
        // to come back through the service rather than a callback.
        workoutService.addConsumer(self)
    }

    func onAppear() {
        loadWorkout()
    }

    func detailText(for exercise: Exercise) -> String {
        exercise.details
    }

    func didTapLogWorkout() {
        navigator.navigate(.modal(.logWorkout(workoutId: workoutId)))
    }

    func didTapEdit() {
        guard let workout else { return }
        navigator.navigate(.modal(.workoutForm(mode: .edit(workout))))
    }

    func didTapDelete() {
        isConfirmingDelete = true
    }

    func didCancelDelete() {
        isConfirmingDelete = false
    }

    func didConfirmDelete() {
        isConfirmingDelete = false

        do {
            try workoutService.deleteWorkout(id: workoutId)
            // The screen is about to describe something that no longer exists.
            navigator.pop()
        } catch {
            errorMessage = "Couldn't delete this workout. \(error.localizedDescription)"
        }
    }

    private func loadWorkout() {
        do {
            guard let workout = try workoutService.fetchWorkout(id: workoutId) else {
                // Deleting pops this screen, so reaching here means it went
                // some other way — don't overwrite what's on screen.
                return
            }
            self.workout = workout
            title = workout.name
            exercises = workout.exercises
        } catch {
            errorMessage = "Couldn't load this workout. \(error.localizedDescription)"
        }
    }
}

// MARK: - WorkoutServiceConsumer

extension WorkoutDetailViewModel: WorkoutServiceConsumer {
    nonisolated func workoutsDidChange(workoutService: any WorkoutService) {
        Task { @MainActor in loadWorkout() }
    }
}
