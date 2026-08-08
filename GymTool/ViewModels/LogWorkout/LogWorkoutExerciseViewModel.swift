import Foundation
import Observation

@MainActor
protocol LogWorkoutExerciseViewModelProtocol: AnyObject, Observable {
    var exerciseId: String { get }
    var exerciseName: String { get }
    var exerciseDetails: String { get }
    var sets: [WorkoutSet] { get }
    /// A workout always keeps at least one set, so the last one can't be removed.
    var canRemoveSet: Bool { get }

    /// The 1-based position of a set, for display.
    func setNumber(forSetId id: String) -> Int
    func repsText(forSetId id: String) -> String
    func weightText(forSetId id: String) -> String
    func addSet()
    func removeSet(id: String)
    func updateReps(_ text: String, setId: String)
    func updateWeight(_ text: String, setId: String)
    /// The sets logged against this exercise, or `nil` when nothing usable was
    /// entered — a set with no reps is not worth persisting.
    func makeExerciseEntry() -> ExerciseEntry?
}

/// Owns the sets logged against a single exercise while a workout is in
/// progress. One of these is vended per exercise by `LogWorkoutViewModel`.
@Observable
@MainActor
final class LogWorkoutExerciseViewModel: LogWorkoutExerciseViewModelProtocol {
    @ObservationIgnored private let exercise: Exercise

    private(set) var sets: [WorkoutSet] = []

    var exerciseId: String { exercise.id }
    var exerciseName: String { exercise.name }
    var exerciseDetails: String { exercise.details }

    var canRemoveSet: Bool { sets.count > 1 }

    init(exercise: Exercise) {
        self.exercise = exercise
        sets = [makeEmptySet()]
    }

    func setNumber(forSetId id: String) -> Int {
        (index(ofSetId: id) ?? 0) + 1
    }

    func repsText(forSetId id: String) -> String {
        guard let set = set(id: id), set.reps > 0 else { return "" }
        return String(set.reps)
    }

    func weightText(forSetId id: String) -> String {
        guard let set = set(id: id), set.weight > 0 else { return "" }
        return set.weight.formattedWeight
    }

    func addSet() {
        sets.append(makeEmptySet())
    }

    func removeSet(id: String) {
        guard canRemoveSet, let index = index(ofSetId: id) else { return }
        sets.remove(at: index)
    }

    func updateReps(_ text: String, setId: String) {
        guard let index = index(ofSetId: setId) else { return }
        let set = sets[index]
        sets[index] = WorkoutSet(
            id: set.id,
            reps: Int(text.trimmed) ?? 0,
            weight: set.weight
        )
    }

    func updateWeight(_ text: String, setId: String) {
        guard let index = index(ofSetId: setId) else { return }
        let set = sets[index]
        sets[index] = WorkoutSet(
            id: set.id,
            reps: set.reps,
            weight: Double(text.trimmed) ?? 0
        )
    }

    func makeExerciseEntry() -> ExerciseEntry? {
        let completedSets = sets.filter { $0.reps > 0 }
        guard !completedSets.isEmpty else { return nil }
        return ExerciseEntry(exerciseId: exercise.id, sets: completedSets)
    }

    private func set(id: String) -> WorkoutSet? {
        sets.first { $0.id == id }
    }

    private func index(ofSetId id: String) -> Int? {
        sets.firstIndex { $0.id == id }
    }

    private func makeEmptySet() -> WorkoutSet {
        WorkoutSet(id: UUID().uuidString, reps: 0, weight: 0)
    }
}
