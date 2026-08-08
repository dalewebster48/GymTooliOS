import Foundation

protocol WorkoutEntryRepository: AnyObject {
    func fetchAll() throws -> [WorkoutEntry]
    /// Every session this exercise has been logged in, newest first.
    func fetchRecordings(exerciseId: String) throws -> [ExerciseRecording]
    func insert(_ entry: WorkoutEntry) throws
    func delete(id: String) throws
}
