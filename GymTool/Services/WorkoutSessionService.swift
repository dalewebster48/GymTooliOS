import Foundation

protocol WorkoutSessionConsumer: AnyObject {
    func sessionDidChange(workoutSessionService: any WorkoutSessionService)
}

protocol WorkoutSessionService: AnyObject {
    /// The workout being recorded, if there is one.
    var currentSession: WorkoutSession? { get }

    /// Resumes the stored session when it is for this workout, and starts a
    /// fresh one otherwise.
    func startSession(workoutId: String) throws
    func addSet(exerciseId: String)
    func removeSet(id: String, exerciseId: String)
    func updateReps(_ text: String, setId: String, exerciseId: String)
    func updateWeight(_ text: String, setId: String, exerciseId: String)
    /// Logs the session and clears it.
    func submit() throws
    /// Abandons the session without logging it.
    func discard()

    func addConsumer(_ consumer: any WorkoutSessionConsumer)
    func removeConsumer(_ consumer: any WorkoutSessionConsumer)
}

final class WorkoutSessionServiceImpl: WorkoutSessionService {
    private let workoutSessionRepository: any WorkoutSessionRepository
    private let workoutService: any WorkoutService
    private let workoutEntryService: any WorkoutEntryService

    private var _consumers: NSHashTable<AnyObject> = .weakObjects()
    private var consumers: [any WorkoutSessionConsumer] {
        _consumers.allObjects.compactMap { $0 as? WorkoutSessionConsumer }
    }

    private(set) var currentSession: WorkoutSession?

    init(
        workoutSessionRepository: any WorkoutSessionRepository,
        workoutService: any WorkoutService,
        workoutEntryService: any WorkoutEntryService
    ) {
        self.workoutSessionRepository = workoutSessionRepository
        self.workoutService = workoutService
        self.workoutEntryService = workoutEntryService

        // Restored before the first screen appears, so a relaunch mid-workout
        // comes back to what was on screen.
        currentSession = try? workoutSessionRepository.fetch()
    }

    func startSession(workoutId: String) throws {
        if currentSession?.workoutId == workoutId {
            return
        }

        guard let workout = try workoutService.fetchWorkout(id: workoutId) else { return }

        // The exercises are copied into the session rather than referenced, so
        // editing or deleting a workout mid-session can't reshape what you are
        // part-way through recording.
        let session = WorkoutSession(
            workoutId: workout.id,
            workoutName: workout.name,
            startedAt: Date(),
            exercises: workout.exercises.map {
                SessionExercise(
                    exerciseId: $0.id,
                    name: $0.name,
                    details: $0.details,
                    sets: [Self.makeEmptySet()]
                )
            }
        )
        store(session)
    }

    func addSet(exerciseId: String) {
        mutate(exerciseId: exerciseId) { exercise in
            exercise.sets.append(Self.makeEmptySet())
        }
    }

    func removeSet(id: String, exerciseId: String) {
        mutate(exerciseId: exerciseId) { exercise in
            // A workout always keeps at least one set to type into.
            guard exercise.sets.count > 1 else { return }
            exercise.sets.removeAll { $0.id == id }
        }
    }

    func updateReps(_ text: String, setId: String, exerciseId: String) {
        mutate(exerciseId: exerciseId) { exercise in
            guard let index = exercise.sets.firstIndex(where: { $0.id == setId }) else { return }
            let set = exercise.sets[index]
            exercise.sets[index] = WorkoutSet(
                id: set.id,
                reps: Int(text.trimmed) ?? 0,
                weight: set.weight
            )
        }
    }

    func updateWeight(_ text: String, setId: String, exerciseId: String) {
        mutate(exerciseId: exerciseId) { exercise in
            guard let index = exercise.sets.firstIndex(where: { $0.id == setId }) else { return }
            let set = exercise.sets[index]
            exercise.sets[index] = WorkoutSet(
                id: set.id,
                reps: set.reps,
                weight: Double(text.trimmed) ?? 0
            )
        }
    }

    func submit() throws {
        guard let session = currentSession else { return }

        let entries = session.exercises.compactMap { exercise -> ExerciseEntry? in
            let sets = exercise.completedSets
            guard !sets.isEmpty else { return nil }
            return ExerciseEntry(exerciseId: exercise.exerciseId, sets: sets)
        }
        guard !entries.isEmpty else { return }

        try workoutEntryService.logWorkout(
            workoutId: session.workoutId,
            startedAt: session.startedAt,
            exerciseEntries: entries
        )
        // Only cleared once the log succeeded, so a failed write leaves the
        // session recoverable.
        clear()
    }

    func discard() {
        clear()
    }

    func addConsumer(_ consumer: any WorkoutSessionConsumer) {
        _consumers.add(consumer)
    }

    func removeConsumer(_ consumer: any WorkoutSessionConsumer) {
        _consumers.remove(consumer)
    }

    private func mutate(
        exerciseId: String,
        _ change: (inout SessionExercise) -> Void
    ) {
        guard var session = currentSession,
              let index = session.exercises.firstIndex(where: { $0.exerciseId == exerciseId })
        else { return }

        change(&session.exercises[index])
        store(session)
    }

    /// Every change is written straight through, so whatever is on screen is
    /// what survives a kill.
    private func store(_ session: WorkoutSession) {
        currentSession = session
        try? workoutSessionRepository.save(session)
        notifyConsumers()
    }

    private func clear() {
        currentSession = nil
        try? workoutSessionRepository.clear()
        notifyConsumers()
    }

    private func notifyConsumers() {
        consumers.forEach { $0.sessionDidChange(workoutSessionService: self) }
    }

    private static func makeEmptySet() -> WorkoutSet {
        WorkoutSet(id: UUID().uuidString, reps: 0, weight: 0)
    }
}
