import Foundation

protocol WorkoutService: AnyObject {
    func fetchWorkouts() throws -> [Workout]
    func fetchWorkout(id: String) throws -> Workout?
    func createWorkout(name: String, exercises: [Exercise]) throws
    func updateWorkout(id: String, name: String, exercises: [Exercise]) throws
    func deleteWorkout(id: String) throws
}

final class WorkoutServiceImpl: WorkoutService {
    private let workoutRepository: any WorkoutRepository

    init(workoutRepository: any WorkoutRepository) {
        self.workoutRepository = workoutRepository
    }

    func fetchWorkouts() throws -> [Workout] {
        try workoutRepository.fetchAll()
    }

    func fetchWorkout(id: String) throws -> Workout? {
        try workoutRepository.fetch(id: id)
    }

    func createWorkout(name: String, exercises: [Exercise]) throws {
        let workout = Workout(
            id: UUID().uuidString,
            name: name,
            exercises: exercises
        )
        try workoutRepository.insert(workout)
    }

    func updateWorkout(id: String, name: String, exercises: [Exercise]) throws {
        let workout = Workout(
            id: id,
            name: name,
            exercises: exercises
        )
        try workoutRepository.update(workout)
    }

    func deleteWorkout(id: String) throws {
        try workoutRepository.delete(id: id)
    }
}
