import Foundation

protocol DataAccessContainer: AnyObject {
    var exerciseRepository: any ExerciseRepository { get }
    var workoutRepository: any WorkoutRepository { get }
    var workoutEntryRepository: any WorkoutEntryRepository { get }
    var workoutSessionRepository: any WorkoutSessionRepository { get }
}

final class AppDataAccessContainer: DataAccessContainer {
    let exerciseRepository: any ExerciseRepository
    let workoutRepository: any WorkoutRepository
    let workoutEntryRepository: any WorkoutEntryRepository
    let workoutSessionRepository: any WorkoutSessionRepository

    init(databaseProvider: any DatabaseProvider) {
        exerciseRepository = SQLiteExerciseRepository(databaseProvider: databaseProvider)
        workoutRepository = SQLiteWorkoutRepository(databaseProvider: databaseProvider)
        workoutEntryRepository = SQLiteWorkoutEntryRepository(databaseProvider: databaseProvider)
        // Not SQLite: one small record that only has to outlive a kill.
        workoutSessionRepository = UserDefaultsWorkoutSessionRepository()
    }
}
