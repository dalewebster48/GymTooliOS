import Foundation

protocol WorkoutEntryRepository: AnyObject {
    func fetchAll() throws -> [WorkoutEntry]
    func insert(_ entry: WorkoutEntry) throws
    func delete(id: String) throws
}
