import Foundation

/// Whether the exercise form is creating a new exercise or editing one that
/// already exists. The screen is otherwise identical in both cases.
enum ExerciseFormMode {
    case create
    case edit(Exercise)
}

protocol ExerciseFormViewModelProtocol: AnyObject {
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
    var viewDelegate: (any ExerciseFormViewModelViewDelegate)? { get set }

    func didUpdateName(_ name: String)
    func didUpdateDetails(_ details: String)
    func didTapSave()
    func didConfirmDelete()
    func didTapCancel()
}

protocol ExerciseFormViewModelViewDelegate: AnyObject {
    func bind(viewModel: any ExerciseFormViewModelProtocol)
}

final class ExerciseFormViewModel: ExerciseFormViewModelProtocol {
    private let mode: ExerciseFormMode
    private let exerciseService: any ExerciseService
    private let navigator: any Navigator
    private let onSave: () -> Void

    weak var viewDelegate: (any ExerciseFormViewModelViewDelegate)? {
        didSet { bind() }
    }

    var name: String {
        didSet { bind() }
    }

    var details: String {
        didSet { bind() }
    }

    var errorMessage: String? {
        didSet { bind() }
    }

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
        navigator: any Navigator,
        onSave: @escaping () -> Void
    ) {
        self.mode = mode
        self.exerciseService = exerciseService
        self.navigator = navigator
        self.onSave = onSave

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
            onSave()
            navigator.dismiss()
        } catch {
            errorMessage = "Couldn't save this exercise. \(error.localizedDescription)"
        }
    }

    func didConfirmDelete() {
        guard case .edit(let exercise) = mode else { return }

        do {
            try exerciseService.deleteExercise(id: exercise.id)
            onSave()
            navigator.dismiss()
        } catch {
            errorMessage = "Couldn't delete this exercise. \(error.localizedDescription)"
        }
    }

    func didTapCancel() {
        navigator.dismiss()
    }

    private func bind() {
        Task { @MainActor in
            viewDelegate?.bind(viewModel: self)
        }
    }
}
