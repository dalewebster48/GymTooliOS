import Foundation

protocol ExerciseRepository: AnyObject {
    func fetchAll() throws -> [Exercise]
    func insert(_ exercise: Exercise) throws
    func update(_ exercise: Exercise) throws
    func delete(id: String) throws
}
