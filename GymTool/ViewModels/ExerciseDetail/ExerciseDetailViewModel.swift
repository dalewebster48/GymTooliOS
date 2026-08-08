import Foundation
import Observation

@MainActor
protocol ExerciseDetailViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var name: String { get }
    var details: String { get }
    var canSave: Bool { get }
    var recordings: [ExerciseRecording] { get }
    var hasRecordings: Bool { get }
    var recordingsSectionTitle: String { get }
    var noRecordingsMessage: String { get }
    var deleteButtonTitle: String { get }
    var deleteConfirmationTitle: String { get }
    var deleteConfirmationMessage: String { get }
    var isConfirmingDelete: Bool { get }
    var errorMessage: String? { get }

    func onAppear()
    func sessionTitle(for recording: ExerciseRecording) -> String
    func setNumberText(forSetId id: String) -> String
    func setDetailText(for set: WorkoutSet) -> String
    func didUpdateName(_ name: String)
    func didUpdateDetails(_ details: String)
    func didTapSave()
    func didTapDelete()
    func didConfirmDelete()
    func didCancelDelete()
}

@Observable
@MainActor
final class ExerciseDetailViewModel: ExerciseDetailViewModelProtocol {
    @ObservationIgnored private let exerciseId: String
    @ObservationIgnored private let exerciseService: any ExerciseService
    @ObservationIgnored private let workoutEntryService: any WorkoutEntryService
    @ObservationIgnored private let navigator: any Navigator

    let title = "Exercise"

    var name = ""
    var details = ""
    var recordings: [ExerciseRecording] = []
    var errorMessage: String?
    var isConfirmingDelete = false

    let recordingsSectionTitle = "RECENT RECORDINGS"
    let noRecordingsMessage = "You haven't logged this exercise yet."
    let deleteButtonTitle = "Delete Exercise"
    let deleteConfirmationTitle = "Delete this exercise?"
    let deleteConfirmationMessage = "It will also be removed from any workouts that use it. Workouts you've already logged keep their records."

    var canSave: Bool {
        !name.trimmed.isEmpty
    }

    var hasRecordings: Bool {
        !recordings.isEmpty
    }

    init(
        exerciseId: String,
        exerciseService: any ExerciseService,
        workoutEntryService: any WorkoutEntryService,
        navigator: any Navigator
    ) {
        self.exerciseId = exerciseId
        self.exerciseService = exerciseService
        self.workoutEntryService = workoutEntryService
        self.navigator = navigator

        // Logging a session elsewhere adds to this exercise's history.
        workoutEntryService.addConsumer(self)
    }

    func onAppear() {
        loadExercise()
        loadRecordings()
    }

    func sessionTitle(for recording: ExerciseRecording) -> String {
        recording.performedAt.historyFormatted
    }

    func setNumberText(forSetId id: String) -> String {
        for recording in recordings {
            if let position = recording.sets.firstIndex(where: { $0.id == id }) {
                return "Set \(position + 1)"
            }
        }
        return ""
    }

    func setDetailText(for set: WorkoutSet) -> String {
        guard set.weight > 0 else { return "\(set.reps) reps" }
        return "\(set.reps) reps × \(set.weight.formattedWeight) kg"
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
            try exerciseService.updateExercise(
                id: exerciseId,
                name: name.trimmed,
                details: details.trimmed
            )
            navigator.pop()
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

        do {
            try exerciseService.deleteExercise(id: exerciseId)
            navigator.pop()
        } catch {
            errorMessage = "Couldn't delete this exercise. \(error.localizedDescription)"
        }
    }

    private func loadExercise() {
        do {
            guard let exercise = try exerciseService.fetchExercises()
                .first(where: { $0.id == exerciseId }) else {
                return
            }
            name = exercise.name
            details = exercise.details
        } catch {
            errorMessage = "Couldn't load this exercise. \(error.localizedDescription)"
        }
    }

    private func loadRecordings() {
        do {
            recordings = try workoutEntryService.fetchRecentRecordings(exerciseId: exerciseId)
        } catch {
            recordings = []
            errorMessage = "Couldn't load your recordings. \(error.localizedDescription)"
        }
    }
}

// MARK: - WorkoutEntryServiceConsumer

extension ExerciseDetailViewModel: WorkoutEntryServiceConsumer {
    nonisolated func entriesDidChange(workoutEntryService: any WorkoutEntryService) {
        Task { @MainActor in loadRecordings() }
    }
}
