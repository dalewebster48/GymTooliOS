import Foundation

/// A workout being recorded right now. Held in memory by
/// `WorkoutSessionService` and written to disk on every change, so killing the
/// app mid-workout doesn't lose what you've already lifted.
struct WorkoutSession: Codable, Hashable {
    let workoutId: String
    /// Denormalised so the resume row can label itself without a lookup, and so
    /// it still reads correctly if the workout is deleted mid-session.
    let workoutName: String
    let startedAt: Date
    var caloriesText: String
    var exercises: [SessionExercise]

    /// Calories are optional — a session is worth recording whether or not you
    /// bothered to enter them.
    var caloriesBurnt: Int? {
        Int(caloriesText.trimmed)
    }

    /// A session is worth submitting once any exercise has a usable set.
    var hasLoggedSets: Bool {
        exercises.contains { !$0.completedSets.isEmpty }
    }

    func exercise(id: String) -> SessionExercise? {
        exercises.first { $0.exerciseId == id }
    }
}

struct SessionExercise: Codable, Hashable, Identifiable {
    var id: String { exerciseId }

    let exerciseId: String
    let name: String
    let details: String
    var sets: [WorkoutSet]

    /// A set with no reps was started and never filled in — not worth keeping.
    var completedSets: [WorkoutSet] {
        sets.filter { $0.reps > 0 }
    }
}
