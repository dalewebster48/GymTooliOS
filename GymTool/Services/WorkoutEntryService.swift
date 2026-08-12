import Foundation

protocol WorkoutEntryServiceConsumer: AnyObject {
    func entriesDidChange(workoutEntryService: any WorkoutEntryService)
}

protocol WorkoutEntryService: AnyObject {
    func logWorkout(workoutId: String, startedAt: Date, exerciseEntries: [ExerciseEntry]) throws
    func fetchHistory() throws -> [WorkoutHistoryItem]
    func fetchHistoryDetail(entryId: String) throws -> WorkoutHistoryDetail?
    /// Records the Apple Health workout this session matched, with its metrics.
    func linkHealthWorkout(entryId: String, healthWorkout: HealthWorkout) throws
    /// The most recent sessions this exercise was logged in, newest first.
    func fetchRecentRecordings(exerciseId: String) throws -> [ExerciseRecording]
    func deleteEntry(id: String) throws

    func addConsumer(_ consumer: any WorkoutEntryServiceConsumer)
    func removeConsumer(_ consumer: any WorkoutEntryServiceConsumer)
}

final class WorkoutEntryServiceImpl: WorkoutEntryService {
    /// Shown when a logged session outlives the workout it was performed from.
    private static let deletedWorkoutName = "Deleted workout"
    /// Shown when logged sets outlive the exercise they were performed against.
    private static let deletedExerciseName = "Deleted exercise"
    /// How many past sessions the exercise detail screen shows.
    private static let recentRecordingLimit = 5

    private let workoutEntryRepository: any WorkoutEntryRepository
    private let workoutRepository: any WorkoutRepository
    private let exerciseRepository: any ExerciseRepository

    private var _consumers: NSHashTable<AnyObject> = .weakObjects()
    private var consumers: [any WorkoutEntryServiceConsumer] {
        _consumers.allObjects.compactMap { $0 as? WorkoutEntryServiceConsumer }
    }

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
        startedAt: Date,
        exerciseEntries: [ExerciseEntry]
    ) throws {
        let entry = WorkoutEntry(
            id: UUID().uuidString,
            workoutId: workoutId,
            performedAt: Date(),
            // Filled in by the Apple Health sync, not by hand.
            caloriesBurnt: nil,
            exerciseEntries: exerciseEntries,
            startedAt: startedAt,
            healthWorkoutId: nil,
            averageHeartRate: nil,
            duration: nil
        )
        try workoutEntryRepository.insert(entry)
        notifyConsumers()
    }

    func linkHealthWorkout(entryId: String, healthWorkout: HealthWorkout) throws {
        try workoutEntryRepository.linkHealthWorkout(
            entryId: entryId,
            healthWorkoutId: healthWorkout.id.uuidString,
            caloriesBurnt: healthWorkout.activeEnergyBurned,
            averageHeartRate: healthWorkout.averageHeartRate,
            duration: healthWorkout.duration
        )
        notifyConsumers()
    }

    func addConsumer(_ consumer: any WorkoutEntryServiceConsumer) {
        _consumers.add(consumer)
    }

    func removeConsumer(_ consumer: any WorkoutEntryServiceConsumer) {
        _consumers.remove(consumer)
    }

    private func notifyConsumers() {
        consumers.forEach { $0.entriesDidChange(workoutEntryService: self) }
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
                caloriesBurnt: entry.caloriesBurnt,
                healthWorkoutId: entry.healthWorkoutId
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
            },
            startedAt: entry.startedAt,
            healthWorkoutId: entry.healthWorkoutId,
            averageHeartRate: entry.averageHeartRate,
            duration: entry.duration
        )
    }

    func fetchRecentRecordings(exerciseId: String) throws -> [ExerciseRecording] {
        // Limited here rather than in SQL: a LIMIT would cap the number of
        // sets, and what's wanted is a number of sessions.
        let recordings = try workoutEntryRepository.fetchRecordings(exerciseId: exerciseId)
        return Array(recordings.prefix(Self.recentRecordingLimit))
    }

    func deleteEntry(id: String) throws {
        try workoutEntryRepository.delete(id: id)
        notifyConsumers()
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
