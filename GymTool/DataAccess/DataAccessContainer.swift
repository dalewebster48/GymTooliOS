import Foundation

protocol DataAccessContainer: AnyObject {
    var exerciseRepository: any ExerciseRepository { get }
    var workoutRepository: any WorkoutRepository { get }
    var workoutEntryRepository: any WorkoutEntryRepository { get }
    var workoutSessionRepository: any WorkoutSessionRepository { get }
    var healthRepository: any HealthRepository { get }
    var notificationRepository: any NotificationRepository { get }
    var screenBrightnessRepository: any ScreenBrightnessRepository { get }
}

final class AppDataAccessContainer: DataAccessContainer {
    let exerciseRepository: any ExerciseRepository
    let workoutRepository: any WorkoutRepository
    let workoutEntryRepository: any WorkoutEntryRepository
    let workoutSessionRepository: any WorkoutSessionRepository
    let healthRepository: any HealthRepository
    let notificationRepository: any NotificationRepository
    let screenBrightnessRepository: any ScreenBrightnessRepository

    init(databaseProvider: any DatabaseProvider) {
        exerciseRepository = SQLiteExerciseRepository(databaseProvider: databaseProvider)
        workoutRepository = SQLiteWorkoutRepository(databaseProvider: databaseProvider)
        workoutEntryRepository = SQLiteWorkoutEntryRepository(databaseProvider: databaseProvider)
        // Not SQLite: one small record that only has to outlive a kill.
        workoutSessionRepository = UserDefaultsWorkoutSessionRepository()
        // Not backed by our own store at all — Apple Health is the source.
        healthRepository = HealthKitRepository()
        notificationRepository = UserNotificationRepository()
        screenBrightnessRepository = UIScreenBrightnessRepository()
    }
}
