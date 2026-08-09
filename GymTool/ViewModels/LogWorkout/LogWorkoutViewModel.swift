import Foundation
import Observation

@MainActor
protocol LogWorkoutViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var exercises: [SessionExercise] { get }
    var caloriesText: String { get }
    var canSubmit: Bool { get }
    var errorMessage: String? { get }
    var exercisesSectionTitle: String { get }
    var discardButtonTitle: String { get }
    var discardConfirmationTitle: String { get }
    var discardConfirmationMessage: String { get }
    var isConfirmingDiscard: Bool { get }

    func onAppear()
    func progressText(for exercise: SessionExercise) -> String
    func didSelectExercise(id: String)
    func didUpdateCalories(_ text: String)
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
    var exercises: [SessionExercise] = []
    var caloriesText = ""
    var errorMessage: String?
    var isConfirmingDiscard = false

    let exercisesSectionTitle = "EXERCISES"
    let discardButtonTitle = "Discard Session"
    let discardConfirmationTitle = "Discard this session?"
    let discardConfirmationMessage = "Everything you've recorded so far will be lost."

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
        switch count {
        case 0: return "Not logged yet"
        case 1: return "1 set"
        default: return "\(count) sets"
        }
    }

    func didSelectExercise(id: String) {
        guard exercises.contains(where: { $0.exerciseId == id }) else { return }
        navigator.navigate(.push(.recordExercise(exerciseId: id)))
    }

    func didUpdateCalories(_ text: String) {
        workoutSessionService.updateCalories(text)
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
        caloriesText = session.caloriesText
    }
}

// MARK: - WorkoutSessionConsumer

extension LogWorkoutViewModel: WorkoutSessionConsumer {
    nonisolated func sessionDidChange(workoutSessionService: any WorkoutSessionService) {
        Task { @MainActor in readSession() }
    }
}
