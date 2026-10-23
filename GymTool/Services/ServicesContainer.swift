import Foundation

final class ServicesContainer {
    let exerciseService: any ExerciseService
    let workoutService: any WorkoutService
    let workoutEntryService: any WorkoutEntryService
    let workoutSessionService: any WorkoutSessionService
    let healthService: any HealthService
    let healthLinkReminderService: any HealthLinkReminderService

    init(dataAccess: any DataAccessContainer) {
        exerciseService = ExerciseServiceImpl(
            exerciseRepository: dataAccess.exerciseRepository
        )
        workoutService = WorkoutServiceImpl(
            workoutRepository: dataAccess.workoutRepository
        )
        let healthService = HealthServiceImpl(
            healthRepository: dataAccess.healthRepository
        )
        self.healthService = healthService
        let healthLinkReminderService = HealthLinkReminderServiceImpl(
            notificationRepository: dataAccess.notificationRepository,
            healthService: healthService
        )
        self.healthLinkReminderService = healthLinkReminderService
        let workoutEntryService = WorkoutEntryServiceImpl(
            workoutEntryRepository: dataAccess.workoutEntryRepository,
            workoutRepository: dataAccess.workoutRepository,
            exerciseRepository: dataAccess.exerciseRepository,
            healthLinkReminderService: healthLinkReminderService
        )
        self.workoutEntryService = workoutEntryService

        // Submitting has to log the session and clear it, and those must not
        // come apart.
        workoutSessionService = WorkoutSessionServiceImpl(
            workoutSessionRepository: dataAccess.workoutSessionRepository,
            workoutService: workoutService,
            workoutEntryService: workoutEntryService
        )
    }
}
