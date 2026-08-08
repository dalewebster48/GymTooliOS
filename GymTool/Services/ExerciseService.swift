import Foundation

protocol ExerciseService: AnyObject {
    func fetchExercises() throws -> [Exercise]
    func createExercise(name: String, details: String) throws
    func updateExercise(id: String, name: String, details: String) throws
    func deleteExercise(id: String) throws
}

final class ExerciseServiceImpl: ExerciseService {
    private let exerciseRepository: any ExerciseRepository

    init(exerciseRepository: any ExerciseRepository) {
        self.exerciseRepository = exerciseRepository
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
    }

    func updateExercise(id: String, name: String, details: String) throws {
        let exercise = Exercise(
            id: id,
            name: name,
            details: details
        )
        try exerciseRepository.update(exercise)
    }

    func deleteExercise(id: String) throws {
        try exerciseRepository.delete(id: id)
    }
}
