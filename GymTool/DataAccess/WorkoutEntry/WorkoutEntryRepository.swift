import Foundation

protocol WorkoutEntryRepository: AnyObject {
    func fetchAll() throws -> [WorkoutEntry]
    /// Every session this exercise has been logged in, newest first.
    func fetchRecordings(exerciseId: String) throws -> [ExerciseRecording]
    func insert(_ entry: WorkoutEntry) throws
    /// Records the Apple Health workout this session was matched to, together
    /// with the metrics pulled from it. The only place link state is set.
    func linkHealthWorkout(
        entryId: String,
        healthWorkoutId: String,
        caloriesBurnt: Int?,
        averageHeartRate: Double?,
        duration: TimeInterval?
    ) throws
    func delete(id: String) throws
}
