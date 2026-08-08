import Foundation
import Observation

/// Whether the exercise form is creating a new exercise or editing one that
/// already exists. The screen is otherwise identical in both cases.
enum ExerciseFormMode: Hashable {
    case create
    case edit(Exercise)
}

@MainActor
protocol ExerciseFormViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var name: String { get }
    var details: String { get }
    var canSave: Bool { get }
    /// Only an exercise that already exists can be deleted.
    var canDelete: Bool { get }
    var deleteButtonTitle: String { get }
    var deleteConfirmationTitle: String { get }
    var deleteConfirmationMessage: String { get }
    var errorMessage: String? { get }
    var isConfirmingDelete: Bool { get }
    func didUpdateName(_ name: String)
    func didUpdateDetails(_ details: String)
    func didTapSave()
    func didTapDelete()
    func didConfirmDelete()
    func didCancelDelete()
    func didTapCancel()
}

@Observable
@MainActor
final class ExerciseFormViewModel: ExerciseFormViewModelProtocol {
    @ObservationIgnored private let mode: ExerciseFormMode
    @ObservationIgnored private let exerciseService: any ExerciseService
    @ObservationIgnored private let navigator: any Navigator

    var name: String

    var details: String

    var errorMessage: String?

    /// Owned here rather than by the view so the whole delete flow stays in
    /// one testable place.
    var isConfirmingDelete = false

    var title: String {
        switch mode {
        case .create: "New Exercise"
        case .edit: "Edit Exercise"
        }
    }

    var canSave: Bool {
        !name.trimmed.isEmpty
    }

    var canDelete: Bool {
        switch mode {
        case .create: false
        case .edit: true
        }
    }

    let deleteButtonTitle = "Delete Exercise"
    let deleteConfirmationTitle = "Delete this exercise?"
    let deleteConfirmationMessage = "It will also be removed from any workouts that use it. Workouts you've already logged keep their records."

    init(
        mode: ExerciseFormMode,
        exerciseService: any ExerciseService,
        navigator: any Navigator
    ) {
        self.mode = mode
        self.exerciseService = exerciseService
        self.navigator = navigator

        switch mode {
        case .create:
            name = ""
            details = ""
        case .edit(let exercise):
            name = exercise.name
            details = exercise.details
        }
    }

    func didUpdateName(_ name: String) {
        self.name = name
    }

    func didUpdateDetails(_ details: String) {
        self.details = details
    }

    func didTapSave() {
        guard canSave else { return }

        do {
            switch mode {
            case .create:
                try exerciseService.createExercise(
                    name: name.trimmed,
                    details: details.trimmed
                )
            case .edit(let exercise):
                try exerciseService.updateExercise(
                    id: exercise.id,
                    name: name.trimmed,
                    details: details.trimmed
                )
            }
            navigator.dismiss()
        } catch {
            errorMessage = "Couldn't save this exercise. \(error.localizedDescription)"
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

        guard case .edit(let exercise) = mode else { return }

        do {
            try exerciseService.deleteExercise(id: exercise.id)
            navigator.dismiss()
        } catch {
            errorMessage = "Couldn't delete this exercise. \(error.localizedDescription)"
        }
    }

    func didTapCancel() {
        navigator.dismiss()
    }
}
