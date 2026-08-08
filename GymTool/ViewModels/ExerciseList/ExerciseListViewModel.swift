import Foundation
import Observation

@MainActor
protocol ExerciseListViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var exercises: [Exercise] { get }
    var emptyStateMessage: String { get }
    var isEmpty: Bool { get }

    func onAppear()
    func didTapCreateExercise()
    func didSelectExercise(id: String)
}

@Observable
@MainActor
final class ExerciseListViewModel: ExerciseListViewModelProtocol {
    @ObservationIgnored private let exerciseService: any ExerciseService
    @ObservationIgnored private let navigator: any Navigator

    let title = "Exercises"

    var exercises: [Exercise] = []
    var emptyStateMessage = ""

    var isEmpty: Bool {
        exercises.isEmpty
    }

    init(
        exerciseService: any ExerciseService,
        navigator: any Navigator
    ) {
        self.exerciseService = exerciseService
        self.navigator = navigator

        exerciseService.addConsumer(self)
    }

    func onAppear() {
        loadExercises()
    }

    func didTapCreateExercise() {
        navigator.navigate(.modal(.exerciseForm(mode: .create)))
    }

    func didSelectExercise(id: String) {
        guard exercises.contains(where: { $0.id == id }) else { return }
        navigator.navigate(.push(.exerciseDetail(exerciseId: id)))
    }

    private func loadExercises() {
        do {
            exercises = try exerciseService.fetchExercises()
            emptyStateMessage = "No exercises yet.\nTap + to create one."
        } catch {
            exercises = []
            emptyStateMessage = "Couldn't load your exercises.\n\(error.localizedDescription)"
        }
    }
}

// MARK: - ExerciseServiceConsumer

extension ExerciseListViewModel: ExerciseServiceConsumer {
    nonisolated func exercisesDidChange(exerciseService: any ExerciseService) {
        Task { @MainActor in loadExercises() }
    }
}
