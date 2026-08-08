import Foundation
import Observation

@MainActor
protocol WorkoutListViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var workouts: [Workout] { get }
    var emptyStateMessage: String { get }
    var isEmpty: Bool { get }

    func onAppear()
    func subtitle(for workout: Workout) -> String
    func didSelectWorkout(id: String)
    func didSelectEditWorkout(id: String)
    func didTapCreateWorkout()
    func didTapManageExercises()
}

@Observable
@MainActor
final class WorkoutListViewModel: WorkoutListViewModelProtocol {
    @ObservationIgnored private let workoutService: any WorkoutService
    @ObservationIgnored private let exerciseService: any ExerciseService
    @ObservationIgnored private let navigator: any Navigator

    let title = "Workouts"

    var workouts: [Workout] = []
    var emptyStateMessage = ""

    var isEmpty: Bool {
        workouts.isEmpty
    }

    init(
        workoutService: any WorkoutService,
        exerciseService: any ExerciseService,
        navigator: any Navigator
    ) {
        self.workoutService = workoutService
        self.exerciseService = exerciseService
        self.navigator = navigator

        // Deleting an exercise rewrites the workouts that contained it, so this
        // list has to follow exercise changes as well as its own.
        workoutService.addConsumer(self)
        exerciseService.addConsumer(self)
    }

    func onAppear() {
        loadWorkouts()
    }

    func subtitle(for workout: Workout) -> String {
        let count = workout.exercises.count
        return count == 1 ? "1 exercise" : "\(count) exercises"
    }

    func didSelectWorkout(id: String) {
        guard let workout = workout(id: id) else { return }
        navigator.navigate(.modal(.logWorkout(workoutId: workout.id)))
    }

    func didSelectEditWorkout(id: String) {
        guard let workout = workout(id: id) else { return }
        presentForm(mode: .edit(workout))
    }

    private func workout(id: String) -> Workout? {
        workouts.first { $0.id == id }
    }

    func didTapCreateWorkout() {
        presentForm(mode: .create)
    }

    private func presentForm(mode: WorkoutFormMode) {
        navigator.navigate(.modal(.workoutForm(mode: mode)))
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
}

// MARK: - WorkoutServiceConsumer

extension WorkoutListViewModel: WorkoutServiceConsumer {
    nonisolated func workoutsDidChange(workoutService: any WorkoutService) {
        Task { @MainActor in loadWorkouts() }
    }
}

// MARK: - ExerciseServiceConsumer

extension WorkoutListViewModel: ExerciseServiceConsumer {
    nonisolated func exercisesDidChange(exerciseService: any ExerciseService) {
        Task { @MainActor in loadWorkouts() }
    }
}
