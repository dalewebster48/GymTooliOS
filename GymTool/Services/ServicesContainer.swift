import Foundation

final class ServicesContainer {
    let exerciseService: any ExerciseService
    let workoutService: any WorkoutService
    let workoutEntryService: any WorkoutEntryService

    init(dataAccess: any DataAccessContainer) {
        exerciseService = ExerciseServiceImpl(
            exerciseRepository: dataAccess.exerciseRepository
        )
        workoutService = WorkoutServiceImpl(
            workoutRepository: dataAccess.workoutRepository
        )
        workoutEntryService = WorkoutEntryServiceImpl(
            workoutEntryRepository: dataAccess.workoutEntryRepository,
            workoutRepository: dataAccess.workoutRepository,
            exerciseRepository: dataAccess.exerciseRepository
        )
    }
}
