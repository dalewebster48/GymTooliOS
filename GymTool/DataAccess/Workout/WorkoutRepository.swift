import Foundation

protocol WorkoutRepository: AnyObject {
    func fetchAll() throws -> [Workout]
    func fetch(id: String) throws -> Workout?
    func insert(_ workout: Workout) throws
    func update(_ workout: Workout) throws
    func delete(id: String) throws
}
