import Foundation

final class ServicesContainer {
    let exerciseService: any ExerciseService
    let workoutService: any WorkoutService
    let workoutEntryService: any WorkoutEntryService
    let workoutSessionService: any WorkoutSessionService
    let healthService: any HealthService

    init(dataAccess: any DataAccessContainer) {
        exerciseService = ExerciseServiceImpl(
            exerciseRepository: dataAccess.exerciseRepository
        )
        workoutService = WorkoutServiceImpl(
            workoutRepository: dataAccess.workoutRepository
        )
        let workoutEntryService = WorkoutEntryServiceImpl(
            workoutEntryRepository: dataAccess.workoutEntryRepository,
            workoutRepository: dataAccess.workoutRepository,
            exerciseRepository: dataAccess.exerciseRepository
        )
        self.workoutEntryService = workoutEntryService

        // The one service that depends on another: submitting has to log the
        // session and clear it, and those must not come apart.
        workoutSessionService = WorkoutSessionServiceImpl(
            workoutSessionRepository: dataAccess.workoutSessionRepository,
            workoutService: workoutService,
            workoutEntryService: workoutEntryService
        )
        healthService = HealthServiceImpl(
            healthRepository: dataAccess.healthRepository
        )
    }
}
