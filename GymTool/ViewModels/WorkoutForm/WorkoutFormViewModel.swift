import Foundation
import Observation

/// Whether the workout form is building a new workout or editing one that
/// already exists. The screen is otherwise identical in both cases.
enum WorkoutFormMode: Hashable {
    case create
    case edit(Workout)
}

@MainActor
protocol WorkoutFormViewModelProtocol: AnyObject, Observable {
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
    var isConfirmingDelete: Bool { get }
    func onAppear()
    /// The 1-based position of an exercise in the workout, or `nil` when it is
    /// not selected. Selection order is the order the exercises are performed.
    func selectionOrder(forExerciseId id: String) -> Int?
    func didUpdateName(_ name: String)
    func didToggleExercise(id: String)
    func didTapSave()
    func didTapDelete()
    func didConfirmDelete()
    func didCancelDelete()
    func didTapCancel()
}

@Observable
@MainActor
final class WorkoutFormViewModel: WorkoutFormViewModelProtocol {
    @ObservationIgnored private let mode: WorkoutFormMode
    @ObservationIgnored private let exerciseService: any ExerciseService
    @ObservationIgnored private let workoutService: any WorkoutService
    @ObservationIgnored private let navigator: any Navigator

    /// Ordered by selection, which becomes the exercise order of the workout.
    private var selectedExerciseIds: [String]

    var name: String

    var exercises: [Exercise] = []

    var errorMessage: String?

    /// Owned here rather than by the view so the whole delete flow stays in
    /// one testable place.
    var isConfirmingDelete = false

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
        navigator: any Navigator
    ) {
        self.mode = mode
        self.exerciseService = exerciseService
        self.workoutService = workoutService
        self.navigator = navigator

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

    func onAppear() {
        loadExercises()
    }

    func selectionOrder(forExerciseId id: String) -> Int? {
        guard let position = selectedExerciseIds.firstIndex(of: id) else { return nil }
        return position + 1
    }

    func didUpdateName(_ name: String) {
        self.name = name
    }

    func didToggleExercise(id: String) {
        guard exercises.contains(where: { $0.id == id }) else { return }

        if let position = selectedExerciseIds.firstIndex(of: id) {
            selectedExerciseIds.remove(at: position)
        } else {
            selectedExerciseIds.append(id)
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
            navigator.dismiss()
        } catch {
            errorMessage = "Couldn't save this workout. \(error.localizedDescription)"
        }
    }

    func didTapDelete() {
        isConfirmingDelete = true
    }

    func didCancelDelete() {
        isConfirmingDelete = false
    }

    func didConfirmDelete() {
        isConfirmingDelete = false

        guard case .edit(let workout) = mode else { return }

        do {
            try workoutService.deleteWorkout(id: workout.id)
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
}
