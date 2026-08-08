import Foundation

/// One past session's sets for a single exercise — what you lifted, and when.
/// Built by joining `entry_sets` back to the session that owns them.
struct ExerciseRecording: Identifiable, Hashable {
    var id: String { entryId }

    let entryId: String
    let performedAt: Date
    let sets: [WorkoutSet]
}
