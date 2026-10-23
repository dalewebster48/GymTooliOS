import Foundation
import Observation

@MainActor
protocol LogWorkoutViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var exercises: [SessionExercise] { get }
    var canSubmit: Bool { get }
    var errorMessage: String? { get }
    var exercisesSectionTitle: String { get }
    var discardButtonTitle: String { get }
    var discardConfirmationTitle: String { get }
    var discardConfirmationMessage: String { get }
    var isConfirmingDiscard: Bool { get }
    var notes: String { get }
    var isFinished: Bool { get }
    var notesSectionTitle: String { get }
    var notesPlaceholder: String { get }
    var finishedTitle: String { get }

    func onAppear()
    func progressText(for exercise: SessionExercise) -> String
    /// Whether anything usable has been recorded against this exercise today.
    func isLogged(_ exercise: SessionExercise) -> Bool
    /// 1-based order this exercise was started in this session, if it has been.
    func performedOrder(for exercise: SessionExercise) -> Int?
    func didSelectExercise(id: String)
    func didUpdateNotes(_ text: String)
    func didUpdateFinished(_ isFinished: Bool)
    func didTapSubmit()
    func didTapCancel()
    func didTapDiscard()
    func didConfirmDiscard()
    func didCancelDiscard()
}

@Observable
@MainActor
final class LogWorkoutViewModel: LogWorkoutViewModelProtocol {
    @ObservationIgnored private let workoutId: String
    @ObservationIgnored private let workoutSessionService: any WorkoutSessionService
    @ObservationIgnored private let navigator: any Navigator

    var title = "Log Workout"
    var exercises: [SessionExercise] = [] {
        didSet { performedOrders = Self.makePerformedOrders(for: exercises) }
    }
    var errorMessage: String?
    var isConfirmingDiscard = false
    var notes = ""
    var isFinished = true

    /// Recomputed once per session change rather than once per row.
    @ObservationIgnored private var performedOrders: [String: Int] = [:]

    let exercisesSectionTitle = "EXERCISES"
    let discardButtonTitle = "Discard Session"
    let discardConfirmationTitle = "Discard this session?"
    let discardConfirmationMessage = "Everything you've recorded so far will be lost."
    let notesSectionTitle = "NOTES"
    let notesPlaceholder = "How did it go?"
    let finishedTitle = "Finished workout"

    var canSubmit: Bool {
        exercises.contains { !$0.completedSets.isEmpty }
    }

    init(
        workoutId: String,
        workoutSessionService: any WorkoutSessionService,
        navigator: any Navigator
    ) {
        self.workoutId = workoutId
        self.workoutSessionService = workoutSessionService
        self.navigator = navigator

        // Sets are recorded on a pushed screen, so this list follows the
        // session rather than owning it.
        workoutSessionService.addConsumer(self)
    }

    func onAppear() {
        do {
            // Resumes when a session for this workout is already in progress.
            try workoutSessionService.startSession(workoutId: workoutId)
        } catch {
            errorMessage = "Couldn't start this workout. \(error.localizedDescription)"
        }
        readSession()
    }

    func progressText(for exercise: SessionExercise) -> String {
        let count = exercise.completedSets.count
        let sets: String
        switch count {
        case 0: return "Not logged yet"
        case 1: sets = "1 set"
        default: sets = "\(count) sets"
        }

        guard let order = performedOrder(for: exercise) else { return sets }
        return "\(sets) · done \(order.ordinalFormatted)"
    }

    func isLogged(_ exercise: SessionExercise) -> Bool {
        !exercise.completedSets.isEmpty
    }

    func performedOrder(for exercise: SessionExercise) -> Int? {
        performedOrders[exercise.exerciseId]
    }

    func didUpdateNotes(_ text: String) {
        workoutSessionService.updateNotes(text)
    }

    func didUpdateFinished(_ isFinished: Bool) {
        workoutSessionService.updateFinished(isFinished)
    }

    func didSelectExercise(id: String) {
        guard exercises.contains(where: { $0.exerciseId == id }) else { return }
        navigator.navigate(.push(.recordExercise(exerciseId: id)))
    }

    func didTapSubmit() {
        do {
            try workoutSessionService.submit()
            navigator.dismiss()
        } catch {
            errorMessage = "Couldn't save this workout. \(error.localizedDescription)"
        }
    }

    /// Closing keeps the session — it stays resumable from Insights. Discard is
    /// the deliberate way to throw it away.
    func didTapCancel() {
        navigator.dismiss()
    }

    func didTapDiscard() {
        isConfirmingDiscard = true
    }

    func didCancelDiscard() {
        isConfirmingDiscard = false
    }

    func didConfirmDiscard() {
        isConfirmingDiscard = false
        workoutSessionService.discard()
        navigator.dismiss()
    }

    private func readSession() {
        guard let session = workoutSessionService.currentSession else { return }
        title = session.workoutName
        exercises = session.exercises
        notes = session.notes
        isFinished = session.isFinished
    }

    private static func makePerformedOrders(for exercises: [SessionExercise]) -> [String: Int] {
        PerformedOrder.ranks(
            startTimes: exercises.map {
                (exerciseId: $0.exerciseId, startedAt: $0.completedSets.firstCompletedAt)
            }
        )
    }
}

// MARK: - WorkoutSessionConsumer

extension LogWorkoutViewModel: WorkoutSessionConsumer {
    nonisolated func sessionDidChange(workoutSessionService: any WorkoutSessionService) {
        Task { @MainActor in readSession() }
    }
}
