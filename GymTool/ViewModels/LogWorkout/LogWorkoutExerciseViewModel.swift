import Foundation

protocol LogWorkoutExerciseViewModelProtocol: AnyObject {
    var exerciseId: String { get }
    var exerciseName: String { get }
    var exerciseDetails: String { get }
    var sets: [WorkoutSet] { get }

    func repsText(at index: Int) -> String
    func weightText(at index: Int) -> String
    func addSet()
    func removeSet(at index: Int)
    func updateReps(_ text: String, at index: Int)
    func updateWeight(_ text: String, at index: Int)
    /// The sets logged against this exercise, or `nil` when nothing usable was
    /// entered — a set with no reps is not worth persisting.
    func makeExerciseEntry() -> ExerciseEntry?
}

/// Owns the sets logged against a single exercise while a workout is in
/// progress. One of these is vended per exercise by `LogWorkoutViewModel`.
final class LogWorkoutExerciseViewModel: LogWorkoutExerciseViewModelProtocol {
    private let exercise: Exercise

    private(set) var sets: [WorkoutSet] = []

    var exerciseId: String { exercise.id }
    var exerciseName: String { exercise.name }
    var exerciseDetails: String { exercise.details }

    init(exercise: Exercise) {
        self.exercise = exercise
        sets = [makeEmptySet()]
    }

    func repsText(at index: Int) -> String {
        guard let set = sets[safe: index], set.reps > 0 else { return "" }
        return String(set.reps)
    }

    func weightText(at index: Int) -> String {
        guard let set = sets[safe: index], set.weight > 0 else { return "" }
        return set.weight.formattedWeight
    }

    func addSet() {
        sets.append(makeEmptySet())
    }

    func removeSet(at index: Int) {
        guard sets.indices.contains(index) else { return }
        sets.remove(at: index)
    }

    func updateReps(_ text: String, at index: Int) {
        guard let set = sets[safe: index] else { return }
        sets[index] = WorkoutSet(
            id: set.id,
            reps: Int(text.trimmed) ?? 0,
            weight: set.weight
        )
    }

    func updateWeight(_ text: String, at index: Int) {
        guard let set = sets[safe: index] else { return }
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

    private func makeEmptySet() -> WorkoutSet {
        WorkoutSet(id: UUID().uuidString, reps: 0, weight: 0)
    }
}

extension Double {
    /// Drops the decimal point for whole numbers so "60" doesn't read "60.0".
    var formattedWeight: String {
        self == rounded() ? String(Int(self)) : String(self)
    }
}
