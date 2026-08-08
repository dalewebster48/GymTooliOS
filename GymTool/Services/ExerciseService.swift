import Foundation

protocol ExerciseServiceConsumer: AnyObject {
    func exercisesDidChange(exerciseService: any ExerciseService)
}

protocol ExerciseService: AnyObject {
    func fetchExercises() throws -> [Exercise]
    func createExercise(name: String, details: String) throws
    func updateExercise(id: String, name: String, details: String) throws
    func deleteExercise(id: String) throws

    func addConsumer(_ consumer: any ExerciseServiceConsumer)
    func removeConsumer(_ consumer: any ExerciseServiceConsumer)
}

final class ExerciseServiceImpl: ExerciseService {
    private let exerciseRepository: any ExerciseRepository

    private var _consumers: NSHashTable<AnyObject> = .weakObjects()
    private var consumers: [any ExerciseServiceConsumer] {
        _consumers.allObjects.compactMap { $0 as? ExerciseServiceConsumer }
    }

    init(exerciseRepository: any ExerciseRepository) {
        self.exerciseRepository = exerciseRepository
    }

    func addConsumer(_ consumer: any ExerciseServiceConsumer) {
        _consumers.add(consumer)
    }

    func removeConsumer(_ consumer: any ExerciseServiceConsumer) {
        _consumers.remove(consumer)
    }

    private func notifyConsumers() {
        consumers.forEach { $0.exercisesDidChange(exerciseService: self) }
    }

    func fetchExercises() throws -> [Exercise] {
        try exerciseRepository.fetchAll()
    }

    func createExercise(name: String, details: String) throws {
        let exercise = Exercise(
            id: UUID().uuidString,
            name: name,
            details: details
        )
        try exerciseRepository.insert(exercise)
        notifyConsumers()
    }

    func updateExercise(id: String, name: String, details: String) throws {
        let exercise = Exercise(
            id: id,
            name: name,
            details: details
        )
        try exerciseRepository.update(exercise)
        notifyConsumers()
    }

    func deleteExercise(id: String) throws {
        try exerciseRepository.delete(id: id)
        notifyConsumers()
    }
}
