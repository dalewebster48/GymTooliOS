import Foundation
import SQLite

final class SQLiteWorkoutEntryRepository: WorkoutEntryRepository {
    private let databaseProvider: any DatabaseProvider

    init(databaseProvider: any DatabaseProvider) {
        self.databaseProvider = databaseProvider
    }

    func fetchAll() throws -> [WorkoutEntry] {
        let entriesByWorkout = try loadExerciseEntriesByEntryId()
        let query = WorkoutEntryTable.table.order(WorkoutEntryTable.performedAt.desc)

        return try databaseProvider.connection.prepare(query).map { row in
            let id = row[WorkoutEntryTable.id]
            return WorkoutEntry(
                id: id,
                workoutId: row[WorkoutEntryTable.workoutId],
                performedAt: row[WorkoutEntryTable.performedAt],
                caloriesBurnt: row[WorkoutEntryTable.caloriesBurnt],
                exerciseEntries: entriesByWorkout[id] ?? [],
                startedAt: row[WorkoutEntryTable.startedAt],
                healthWorkoutId: row[WorkoutEntryTable.healthWorkoutId],
                averageHeartRate: row[WorkoutEntryTable.averageHeartRate],
                duration: row[WorkoutEntryTable.duration]
            )
        }
    }

    /// Every set logged against one exercise, grouped back into the sessions
    /// they were performed in. Ordered newest session first, and within a
    /// session in the order the sets were performed.
    func fetchRecordings(exerciseId: String) throws -> [ExerciseRecording] {
        let query = EntrySetTable.table
            .join(
                WorkoutEntryTable.table,
                on: WorkoutEntryTable.table[WorkoutEntryTable.id] == EntrySetTable.entryId
            )
            .filter(EntrySetTable.exerciseId == exerciseId)
            .order(WorkoutEntryTable.performedAt.desc, EntrySetTable.position.asc)

        // Rows arrive in the order we want, but a dictionary won't hold it, so
        // the entry ids are tracked separately as they are first seen.
        var entryIdOrder: [String] = []
        var performedAtByEntry: [String: Date] = [:]
        var setsByEntry: [String: [WorkoutSet]] = [:]

        for row in try databaseProvider.connection.prepare(query) {
            let entryId = row[EntrySetTable.entryId]

            if setsByEntry[entryId] == nil {
                entryIdOrder.append(entryId)
                performedAtByEntry[entryId] = row[WorkoutEntryTable.performedAt]
            }

            setsByEntry[entryId, default: []].append(
                WorkoutSet(
                    // `id` is ambiguous across the joined tables.
                    id: row[EntrySetTable.table[EntrySetTable.id]],
                    reps: row[EntrySetTable.reps],
                    weight: row[EntrySetTable.weight]
                )
            )
        }

        return entryIdOrder.compactMap { entryId in
            guard let performedAt = performedAtByEntry[entryId] else { return nil }
            return ExerciseRecording(
                entryId: entryId,
                performedAt: performedAt,
                sets: setsByEntry[entryId] ?? []
            )
        }
    }

    func linkHealthWorkout(
        entryId: String,
        healthWorkoutId: String,
        caloriesBurnt: Int?,
        averageHeartRate: Double?,
        duration: TimeInterval?
    ) throws {
        let row = WorkoutEntryTable.table.filter(WorkoutEntryTable.id == entryId)
        try databaseProvider.connection.run(
            row.update(
                WorkoutEntryTable.healthWorkoutId <- healthWorkoutId,
                WorkoutEntryTable.caloriesBurnt <- caloriesBurnt,
                WorkoutEntryTable.averageHeartRate <- averageHeartRate,
                WorkoutEntryTable.duration <- duration
            )
        )
    }

    func delete(id: String) throws {
        // `entry_sets` cascades on `entry_id`, so the sets go with it.
        let row = WorkoutEntryTable.table.filter(WorkoutEntryTable.id == id)
        try databaseProvider.connection.run(row.delete())
    }

    func insert(_ entry: WorkoutEntry) throws {
        let connection = databaseProvider.connection

        try connection.transaction {
            try connection.run(
                WorkoutEntryTable.table.insert(
                    WorkoutEntryTable.id <- entry.id,
                    WorkoutEntryTable.workoutId <- entry.workoutId,
                    WorkoutEntryTable.performedAt <- entry.performedAt,
                    WorkoutEntryTable.caloriesBurnt <- entry.caloriesBurnt,
                    WorkoutEntryTable.startedAt <- entry.startedAt,
                    WorkoutEntryTable.healthWorkoutId <- entry.healthWorkoutId,
                    WorkoutEntryTable.averageHeartRate <- entry.averageHeartRate,
                    WorkoutEntryTable.duration <- entry.duration
                )
            )

            // `position` is an ordinal across the whole entry so that reading
            // rows back in position order restores exercise *and* set ordering.
            var position = 0
            for exerciseEntry in entry.exerciseEntries {
                for set in exerciseEntry.sets {
                    try connection.run(
                        EntrySetTable.table.insert(
                            EntrySetTable.id <- set.id,
                            EntrySetTable.entryId <- entry.id,
                            EntrySetTable.exerciseId <- exerciseEntry.exerciseId,
                            EntrySetTable.position <- position,
                            EntrySetTable.reps <- set.reps,
                            EntrySetTable.weight <- set.weight
                        )
                    )
                    position += 1
                }
            }
        }
    }

    /// Rebuilds the `ExerciseEntry` grouping out of the flat `entry_sets` table.
    /// Rows arrive in `position` order, so appending as we go preserves both the
    /// order exercises were logged in and the order of sets within each.
    private func loadExerciseEntriesByEntryId() throws -> [String: [ExerciseEntry]] {
        let query = EntrySetTable.table.order(EntrySetTable.position.asc)

        var setsByEntry: [String: [(exerciseId: String, set: WorkoutSet)]] = [:]
        for row in try databaseProvider.connection.prepare(query) {
            let set = WorkoutSet(
                id: row[EntrySetTable.id],
                reps: row[EntrySetTable.reps],
                weight: row[EntrySetTable.weight]
            )
            setsByEntry[row[EntrySetTable.entryId], default: []]
                .append((exerciseId: row[EntrySetTable.exerciseId], set: set))
        }

        return setsByEntry.mapValues { rows in
            var exerciseIdOrder: [String] = []
            var setsByExercise: [String: [WorkoutSet]] = [:]

            for row in rows {
                if setsByExercise[row.exerciseId] == nil {
                    exerciseIdOrder.append(row.exerciseId)
                }
                setsByExercise[row.exerciseId, default: []].append(row.set)
            }

            return exerciseIdOrder.map { exerciseId in
                ExerciseEntry(exerciseId: exerciseId, sets: setsByExercise[exerciseId] ?? [])
            }
        }
    }
}
