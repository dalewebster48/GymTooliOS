import Foundation
import Observation

@MainActor
protocol RecordExerciseViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var details: String { get }
    var sets: [WorkoutSet] { get }
    var canRemoveSet: Bool { get }
    var recordings: [ExerciseRecording] { get }
    var hasRecordings: Bool { get }
    var recordingsSectionTitle: String { get }
    var noRecordingsMessage: String { get }
    var setsSectionTitle: String { get }
    var addSetTitle: String { get }
    var errorMessage: String? { get }

    func onAppear()
    func setNumber(forSetId id: String) -> Int
    func repsText(forSetId id: String) -> String
    func weightText(forSetId id: String) -> String
    func sessionTitle(for recording: ExerciseRecording) -> String
    func setNumberText(forSetId id: String, in recording: ExerciseRecording) -> String
    func setDetailText(for set: WorkoutSet) -> String
    func didTapAddSet()
    func didDeleteSet(id: String)
    func didUpdateReps(_ text: String, setId: String)
    func didUpdateWeight(_ text: String, setId: String)
}

/// Recording one exercise inside a workout in progress. Sets live on the
/// session service, not here, so they survive leaving this screen — or the app
/// being killed on it.
@Observable
@MainActor
final class RecordExerciseViewModel: RecordExerciseViewModelProtocol {
    @ObservationIgnored private let exerciseId: String
    @ObservationIgnored private let workoutSessionService: any WorkoutSessionService
    @ObservationIgnored private let workoutEntryService: any WorkoutEntryService

    var title = ""
    var details = ""
    var sets: [WorkoutSet] = []
    var recordings: [ExerciseRecording] = []
    var errorMessage: String?

    let recordingsSectionTitle = "RECENT RECORDINGS"
    let noRecordingsMessage = "You haven't logged this exercise before."
    let setsSectionTitle = "THIS SESSION"
    let addSetTitle = "Add Set"

    var canRemoveSet: Bool {
        sets.count > 1
    }

    var hasRecordings: Bool {
        !recordings.isEmpty
    }

    init(
        exerciseId: String,
        workoutSessionService: any WorkoutSessionService,
        workoutEntryService: any WorkoutEntryService
    ) {
        self.exerciseId = exerciseId
        self.workoutSessionService = workoutSessionService
        self.workoutEntryService = workoutEntryService

        workoutSessionService.addConsumer(self)
    }

    func onAppear() {
        readSession()
        loadRecordings()
    }

    func setNumber(forSetId id: String) -> Int {
        (sets.firstIndex { $0.id == id } ?? 0) + 1
    }

    func repsText(forSetId id: String) -> String {
        guard let set = set(id: id), set.reps > 0 else { return "" }
        return String(set.reps)
    }

    func weightText(forSetId id: String) -> String {
        guard let set = set(id: id), set.weight > 0 else { return "" }
        return set.weight.formattedWeight
    }

    func sessionTitle(for recording: ExerciseRecording) -> String {
        recording.performedAt.historyFormatted
    }

    func setNumberText(forSetId id: String, in recording: ExerciseRecording) -> String {
        guard let position = recording.sets.firstIndex(where: { $0.id == id }) else { return "" }
        return "Set \(position + 1)"
    }

    func setDetailText(for set: WorkoutSet) -> String {
        guard set.weight > 0 else { return "\(set.reps) reps" }
        return "\(set.reps) reps × \(set.weight.formattedWeight) kg"
    }

    func didTapAddSet() {
        workoutSessionService.addSet(exerciseId: exerciseId)
    }

    func didDeleteSet(id: String) {
        workoutSessionService.removeSet(id: id, exerciseId: exerciseId)
    }

    func didUpdateReps(_ text: String, setId: String) {
        workoutSessionService.updateReps(text, setId: setId, exerciseId: exerciseId)
    }

    func didUpdateWeight(_ text: String, setId: String) {
        workoutSessionService.updateWeight(text, setId: setId, exerciseId: exerciseId)
    }

    private func set(id: String) -> WorkoutSet? {
        sets.first { $0.id == id }
    }

    private func readSession() {
        guard let exercise = workoutSessionService.currentSession?.exercise(id: exerciseId) else {
            return
        }
        title = exercise.name
        details = exercise.details
        sets = exercise.sets
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

// MARK: - WorkoutSessionConsumer

extension RecordExerciseViewModel: WorkoutSessionConsumer {
    nonisolated func sessionDidChange(workoutSessionService: any WorkoutSessionService) {
        Task { @MainActor in readSession() }
    }
}
