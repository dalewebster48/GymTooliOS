import Foundation

protocol DataAccessContainer: AnyObject {
    var exerciseRepository: any ExerciseRepository { get }
    var workoutRepository: any WorkoutRepository { get }
    var workoutEntryRepository: any WorkoutEntryRepository { get }
}

final class AppDataAccessContainer: DataAccessContainer {
    let exerciseRepository: any ExerciseRepository
    let workoutRepository: any WorkoutRepository
    let workoutEntryRepository: any WorkoutEntryRepository

    init(databaseProvider: any DatabaseProvider) {
        exerciseRepository = SQLiteExerciseRepository(databaseProvider: databaseProvider)
        workoutRepository = SQLiteWorkoutRepository(databaseProvider: databaseProvider)
        workoutEntryRepository = SQLiteWorkoutEntryRepository(databaseProvider: databaseProvider)
    }
}
