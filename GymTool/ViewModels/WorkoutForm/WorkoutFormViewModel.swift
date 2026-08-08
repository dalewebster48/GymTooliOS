import Foundation

/// Whether the workout form is building a new workout or editing one that
/// already exists. The screen is otherwise identical in both cases.
enum WorkoutFormMode {
    case create
    case edit(Workout)
}

protocol WorkoutFormViewModelProtocol: AnyObject {
    var title: String { get }
    var name: String { get }
    var exercises: [Exercise] { get }
    var canSave: Bool { get }
    var canDelete: Bool { get }
    var hasExercises: Bool { get }
    var emptyStateMessage: String { get }
    var deleteButtonTitle: String { get }
    var deleteConfirmationTitle: String { get }
    var deleteConfirmationMessage: String { get }
    var errorMessage: String? { get }
    var viewDelegate: (any WorkoutFormViewModelViewDelegate)? { get set }

    func isSelected(at index: Int) -> Bool
    /// The 1-based position of an exercise in the workout, or `nil` when it is
    /// not selected. Selection order is the order the exercises are performed.
    func selectionOrder(at index: Int) -> Int?
    func didUpdateName(_ name: String)
    func didToggleExercise(at index: Int)
    func didTapSave()
    func didConfirmDelete()
    func didTapCancel()
}

protocol WorkoutFormViewModelViewDelegate: AnyObject {
    func bind(viewModel: any WorkoutFormViewModelProtocol)
}

final class WorkoutFormViewModel: WorkoutFormViewModelProtocol {
    private let mode: WorkoutFormMode
    private let exerciseService: any ExerciseService
    private let workoutService: any WorkoutService
    private let navigator: any Navigator
    private let onSave: () -> Void

    /// Ordered by selection, which becomes the exercise order of the workout.
    private var selectedExerciseIds: [String] {
        didSet { bind() }
    }

    weak var viewDelegate: (any WorkoutFormViewModelViewDelegate)? {
        didSet { loadExercises() }
    }

    var name: String {
        didSet { bind() }
    }

    var exercises: [Exercise] = [] {
        didSet { bind() }
    }

    var errorMessage: String? {
        didSet { bind() }
    }

    let emptyStateMessage = "You need at least one exercise before you can build a workout.\nClose this and tap Manage to create some."
    let deleteButtonTitle = "Delete Workout"
    let deleteConfirmationTitle = "Delete this workout?"
    let deleteConfirmationMessage = "Sessions you've already logged from it are kept."

    var title: String {
        switch mode {
        case .create: "New Workout"
        case .edit: "Edit Workout"
        }
    }

    var canDelete: Bool {
        switch mode {
        case .create: false
        case .edit: true
        }
    }

    var hasExercises: Bool {
        !exercises.isEmpty
    }

    var canSave: Bool {
        !name.trimmed.isEmpty && !selectedExerciseIds.isEmpty
    }

    init(
        mode: WorkoutFormMode,
        exerciseService: any ExerciseService,
        workoutService: any WorkoutService,
        navigator: any Navigator,
        onSave: @escaping () -> Void
    ) {
        self.mode = mode
        self.exerciseService = exerciseService
        self.workoutService = workoutService
        self.navigator = navigator
        self.onSave = onSave

        switch mode {
        case .create:
            name = ""
            selectedExerciseIds = []
        case .edit(let workout):
            name = workout.name
            // Seeded in the workout's own order so existing ordering survives.
            selectedExerciseIds = workout.exercises.map(\.id)
        }
    }

    func isSelected(at index: Int) -> Bool {
        selectionOrder(at: index) != nil
    }

    func selectionOrder(at index: Int) -> Int? {
        guard let exercise = exercises[safe: index] else { return nil }
        guard let position = selectedExerciseIds.firstIndex(of: exercise.id) else { return nil }
        return position + 1
    }

    func didUpdateName(_ name: String) {
        self.name = name
    }

    func didToggleExercise(at index: Int) {
        guard let exercise = exercises[safe: index] else { return }

        if let position = selectedExerciseIds.firstIndex(of: exercise.id) {
            selectedExerciseIds.remove(at: position)
        } else {
            selectedExerciseIds.append(exercise.id)
        }
    }

    func didTapSave() {
        guard canSave else { return }

        let exercisesById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        let selectedExercises = selectedExerciseIds.compactMap { exercisesById[$0] }

        do {
            switch mode {
            case .create:
                try workoutService.createWorkout(
                    name: name.trimmed,
                    exercises: selectedExercises
                )
            case .edit(let workout):
                try workoutService.updateWorkout(
                    id: workout.id,
                    name: name.trimmed,
                    exercises: selectedExercises
                )
            }
            onSave()
            navigator.dismiss()
        } catch {
            errorMessage = "Couldn't save this workout. \(error.localizedDescription)"
        }
    }

    func didConfirmDelete() {
        guard case .edit(let workout) = mode else { return }

        do {
            try workoutService.deleteWorkout(id: workout.id)
            onSave()
            navigator.dismiss()
        } catch {
            errorMessage = "Couldn't delete this workout. \(error.localizedDescription)"
        }
    }

    func didTapCancel() {
        navigator.dismiss()
    }

    private func loadExercises() {
        do {
            exercises = try exerciseService.fetchExercises()
        } catch {
            exercises = []
            errorMessage = "Couldn't load your exercises. \(error.localizedDescription)"
        }
    }

    private func bind() {
        Task { @MainActor in
            viewDelegate?.bind(viewModel: self)
        }
    }
}
