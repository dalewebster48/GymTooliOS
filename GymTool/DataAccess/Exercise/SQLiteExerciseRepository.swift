import Foundation
import SQLite

final class SQLiteExerciseRepository: ExerciseRepository {
    private let databaseProvider: any DatabaseProvider

    init(databaseProvider: any DatabaseProvider) {
        self.databaseProvider = databaseProvider
    }

    func fetchAll() throws -> [Exercise] {
        let query = ExerciseTable.table.order(ExerciseTable.name.asc)
        return try databaseProvider.connection.prepare(query).map { Exercise(row: $0) }
    }

    func insert(_ exercise: Exercise) throws {
        try databaseProvider.connection.run(
            ExerciseTable.table.insert(
                ExerciseTable.id <- exercise.id,
                ExerciseTable.name <- exercise.name,
                ExerciseTable.details <- exercise.details
            )
        )
    }

    func update(_ exercise: Exercise) throws {
        // Workouts reference exercises by id, so renaming one is picked up
        // everywhere it appears without touching `workout_exercises`.
        let row = ExerciseTable.table.filter(ExerciseTable.id == exercise.id)
        try databaseProvider.connection.run(
            row.update(
                ExerciseTable.name <- exercise.name,
                ExerciseTable.details <- exercise.details
            )
        )
    }

    func delete(id: String) throws {
        // `workout_exercises` cascades on this delete, so the exercise also
        // drops out of every workout that referenced it. Logged history in
        // `entry_sets` is deliberately left alone — see note in Schema.swift.
        let row = ExerciseTable.table.filter(ExerciseTable.id == id)
        try databaseProvider.connection.run(row.delete())
    }
}

extension Exercise {
    init(row: Row) {
        self.init(
            id: row[ExerciseTable.id],
            name: row[ExerciseTable.name],
            details: row[ExerciseTable.details]
        )
    }

    /// Reads an exercise from a row produced by a join, where `id` and `name`
    /// are ambiguous and must be namespaced to the `exercises` table.
    init(joinedRow: Row) {
        self.init(
            id: joinedRow[ExerciseTable.table[ExerciseTable.id]],
            name: joinedRow[ExerciseTable.table[ExerciseTable.name]],
            details: joinedRow[ExerciseTable.table[ExerciseTable.details]]
        )
    }
}
