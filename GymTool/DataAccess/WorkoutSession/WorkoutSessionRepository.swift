import Foundation

protocol WorkoutSessionRepository: AnyObject {
    func fetch() throws -> WorkoutSession?
    func save(_ session: WorkoutSession) throws
    func clear() throws
}
