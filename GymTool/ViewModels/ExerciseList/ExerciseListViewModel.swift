import Foundation

protocol ExerciseListViewModelProtocol: AnyObject {
    var title: String { get }
    var exercises: [Exercise] { get }
    var emptyStateMessage: String { get }
    var isEmpty: Bool { get }
    var viewDelegate: (any ExerciseListViewModelViewDelegate)? { get set }

    func didTapCreateExercise()
    func didSelectExercise(at index: Int)
    func didTapDone()
}

protocol ExerciseListViewModelViewDelegate: AnyObject {
    func bind(viewModel: any ExerciseListViewModelProtocol)
}

final class ExerciseListViewModel: ExerciseListViewModelProtocol {
    private let exerciseService: any ExerciseService
    private let navigator: any Navigator

    weak var viewDelegate: (any ExerciseListViewModelViewDelegate)? {
        didSet { loadExercises() }
    }

    let title = "Exercises"

    var exercises: [Exercise] = [] {
        didSet { bind() }
    }

    var emptyStateMessage = "" {
        didSet { bind() }
    }

    var isEmpty: Bool {
        exercises.isEmpty
    }

    init(
        exerciseService: any ExerciseService,
        navigator: any Navigator
    ) {
        self.exerciseService = exerciseService
        self.navigator = navigator
    }

    func didTapCreateExercise() {
        presentForm(mode: .create)
    }

    func didSelectExercise(at index: Int) {
        guard let exercise = exercises[safe: index] else { return }
        presentForm(mode: .edit(exercise))
    }

    private func presentForm(mode: ExerciseFormMode) {
        navigator.navigate(.modal(.exerciseForm(mode: mode, onSave: { [weak self] in
            self?.loadExercises()
        })))
    }

    func didTapDone() {
        navigator.dismiss()
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

    private func bind() {
        Task { @MainActor in
            viewDelegate?.bind(viewModel: self)
        }
    }
}
