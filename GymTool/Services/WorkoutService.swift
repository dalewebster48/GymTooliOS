import Foundation

protocol WorkoutServiceConsumer: AnyObject {
    func workoutsDidChange(workoutService: any WorkoutService)
}

protocol WorkoutService: AnyObject {
    func fetchWorkouts() throws -> [Workout]
    func fetchWorkout(id: String) throws -> Workout?
    func createWorkout(name: String, exercises: [Exercise]) throws
    func updateWorkout(id: String, name: String, exercises: [Exercise]) throws
    func deleteWorkout(id: String) throws

    func addConsumer(_ consumer: any WorkoutServiceConsumer)
    func removeConsumer(_ consumer: any WorkoutServiceConsumer)
}

final class WorkoutServiceImpl: WorkoutService {
    private let workoutRepository: any WorkoutRepository

    private var _consumers: NSHashTable<AnyObject> = .weakObjects()
    private var consumers: [any WorkoutServiceConsumer] {
        _consumers.allObjects.compactMap { $0 as? WorkoutServiceConsumer }
    }

    init(workoutRepository: any WorkoutRepository) {
        self.workoutRepository = workoutRepository
    }

    func addConsumer(_ consumer: any WorkoutServiceConsumer) {
        _consumers.add(consumer)
    }

    func removeConsumer(_ consumer: any WorkoutServiceConsumer) {
        _consumers.remove(consumer)
    }

    private func notifyConsumers() {
        consumers.forEach { $0.workoutsDidChange(workoutService: self) }
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
        notifyConsumers()
    }

    func updateWorkout(id: String, name: String, exercises: [Exercise]) throws {
        let workout = Workout(
            id: id,
            name: name,
            exercises: exercises
        )
        try workoutRepository.update(workout)
        notifyConsumers()
    }

    func deleteWorkout(id: String) throws {
        try workoutRepository.delete(id: id)
        notifyConsumers()
    }
}
