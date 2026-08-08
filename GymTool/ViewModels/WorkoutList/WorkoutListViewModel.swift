import Foundation

protocol WorkoutListViewModelProtocol: AnyObject {
    var title: String { get }
    var workouts: [Workout] { get }
    var emptyStateMessage: String { get }
    var isEmpty: Bool { get }
    var viewDelegate: (any WorkoutListViewModelViewDelegate)? { get set }

    func subtitle(for workout: Workout) -> String
    func didSelectWorkout(at index: Int)
    func didSelectEditWorkout(at index: Int)
    func didTapCreateWorkout()
    func didTapManageExercises()
}

protocol WorkoutListViewModelViewDelegate: AnyObject {
    func bind(viewModel: any WorkoutListViewModelProtocol)
}

final class WorkoutListViewModel: WorkoutListViewModelProtocol {
    private let workoutService: any WorkoutService
    private let navigator: any Navigator

    weak var viewDelegate: (any WorkoutListViewModelViewDelegate)? {
        didSet { loadWorkouts() }
    }

    let title = "Workouts"

    var workouts: [Workout] = [] {
        didSet { bind() }
    }

    var emptyStateMessage = "" {
        didSet { bind() }
    }

    var isEmpty: Bool {
        workouts.isEmpty
    }

    init(
        workoutService: any WorkoutService,
        navigator: any Navigator
    ) {
        self.workoutService = workoutService
        self.navigator = navigator
    }

    func subtitle(for workout: Workout) -> String {
        let count = workout.exercises.count
        return count == 1 ? "1 exercise" : "\(count) exercises"
    }

    func didSelectWorkout(at index: Int) {
        guard let workout = workouts[safe: index] else { return }
        navigator.navigate(.modal(.logWorkout(workoutId: workout.id)))
    }

    func didSelectEditWorkout(at index: Int) {
        guard let workout = workouts[safe: index] else { return }
        presentForm(mode: .edit(workout))
    }

    func didTapCreateWorkout() {
        presentForm(mode: .create)
    }

    private func presentForm(mode: WorkoutFormMode) {
        navigator.navigate(.modal(.workoutForm(mode: mode, onSave: { [weak self] in
            self?.loadWorkouts()
        })))
    }

    func didTapManageExercises() {
        navigator.navigate(.modal(.exerciseList))
    }

    private func loadWorkouts() {
        do {
            workouts = try workoutService.fetchWorkouts()
            emptyStateMessage = "No workouts yet.\nTap + to create one."
        } catch {
            workouts = []
            emptyStateMessage = "Couldn't load your workouts.\n\(error.localizedDescription)"
        }
    }

    private func bind() {
        Task { @MainActor in
            viewDelegate?.bind(viewModel: self)
        }
    }
}
