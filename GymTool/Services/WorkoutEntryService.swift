import Foundation

protocol WorkoutEntryService: AnyObject {
    func logWorkout(workoutId: String, exerciseEntries: [ExerciseEntry], caloriesBurnt: Int?) throws
    func fetchHistory() throws -> [WorkoutHistoryItem]
    func fetchHistoryDetail(entryId: String) throws -> WorkoutHistoryDetail?
    func deleteEntry(id: String) throws
}

final class WorkoutEntryServiceImpl: WorkoutEntryService {
    /// Shown when a logged session outlives the workout it was performed from.
    private static let deletedWorkoutName = "Deleted workout"
    /// Shown when logged sets outlive the exercise they were performed against.
    private static let deletedExerciseName = "Deleted exercise"

    private let workoutEntryRepository: any WorkoutEntryRepository
    private let workoutRepository: any WorkoutRepository
    private let exerciseRepository: any ExerciseRepository

    init(
        workoutEntryRepository: any WorkoutEntryRepository,
        workoutRepository: any WorkoutRepository,
        exerciseRepository: any ExerciseRepository
    ) {
        self.workoutEntryRepository = workoutEntryRepository
        self.workoutRepository = workoutRepository
        self.exerciseRepository = exerciseRepository
    }

    func logWorkout(
        workoutId: String,
        exerciseEntries: [ExerciseEntry],
        caloriesBurnt: Int?
    ) throws {
        let entry = WorkoutEntry(
            id: UUID().uuidString,
            workoutId: workoutId,
            performedAt: Date(),
            caloriesBurnt: caloriesBurnt,
            exerciseEntries: exerciseEntries
        )
        try workoutEntryRepository.insert(entry)
    }

    func fetchHistory() throws -> [WorkoutHistoryItem] {
        // Already ordered newest-first by the repository.
        let entries = try workoutEntryRepository.fetchAll()
        let workoutNames = try workoutNamesById()

        return entries.map { entry in
            WorkoutHistoryItem(
                entryId: entry.id,
                workoutName: workoutNames[entry.workoutId] ?? Self.deletedWorkoutName,
                performedAt: entry.performedAt,
                exerciseCount: entry.exerciseEntries.count,
                setCount: entry.exerciseEntries.reduce(0) { $0 + $1.sets.count },
                caloriesBurnt: entry.caloriesBurnt
            )
        }
    }

    func fetchHistoryDetail(entryId: String) throws -> WorkoutHistoryDetail? {
        guard let entry = try workoutEntryRepository.fetchAll().first(where: { $0.id == entryId }) else {
            return nil
        }

        let workoutNames = try workoutNamesById()
        let exerciseNames = try exerciseNamesById()

        return WorkoutHistoryDetail(
            entryId: entry.id,
            workoutName: workoutNames[entry.workoutId] ?? Self.deletedWorkoutName,
            performedAt: entry.performedAt,
            caloriesBurnt: entry.caloriesBurnt,
            exercises: entry.exerciseEntries.map { exerciseEntry in
                LoggedExercise(
                    exerciseId: exerciseEntry.exerciseId,
                    name: exerciseNames[exerciseEntry.exerciseId] ?? Self.deletedExerciseName,
                    sets: exerciseEntry.sets
                )
            }
        )
    }

    func deleteEntry(id: String) throws {
        try workoutEntryRepository.delete(id: id)
    }

    private func workoutNamesById() throws -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: try workoutRepository.fetchAll().map { ($0.id, $0.name) }
        )
    }

    private func exerciseNamesById() throws -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: try exerciseRepository.fetchAll().map { ($0.id, $0.name) }
        )
    }
}
