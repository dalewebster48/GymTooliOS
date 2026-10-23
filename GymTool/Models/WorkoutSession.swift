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
    var exercises: [SessionExercise]
    var notes: String
    /// Defaults on: most sessions are finished, so it's the exhausted ones you
    /// have to remember to flag.
    var isFinished: Bool

    /// A session is worth submitting once any exercise has a usable set.
    var hasLoggedSets: Bool {
        exercises.contains { !$0.completedSets.isEmpty }
    }

    func exercise(id: String) -> SessionExercise? {
        exercises.first { $0.exerciseId == id }
    }
}

extension WorkoutSession {
    private enum CodingKeys: String, CodingKey {
        case workoutId, workoutName, startedAt, exercises, notes, isFinished
    }

    /// Hand-written so a session saved by an earlier build — without `notes`
    /// or `isFinished` — still restores instead of failing to decode and being
    /// lost. Declared in an extension to keep the memberwise initialiser.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        workoutId = try container.decode(String.self, forKey: .workoutId)
        workoutName = try container.decode(String.self, forKey: .workoutName)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        exercises = try container.decode([SessionExercise].self, forKey: .exercises)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isFinished = try container.decodeIfPresent(Bool.self, forKey: .isFinished) ?? true
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
