import Foundation
import SQLite

protocol DatabaseProvider: AnyObject {
    var connection: Connection { get }
    func migrate() throws
}

final class AppDatabaseProvider: DatabaseProvider {
    let connection: Connection

    init() throws {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let databaseURL = directory.appending(path: "gymtool.sqlite3")
        // `path()` percent-encodes by default, which would turn the space in
        // "Application Support" into %20 and leave SQLite unable to open it.
        connection = try Connection(databaseURL.path(percentEncoded: false))
        try connection.execute("PRAGMA foreign_keys = ON;")
    }

    /// Bump when adding a migration below.
    private static let schemaVersion = 1

    func migrate() throws {
        try createTables()
        try runMigrations()
    }

    /// The original schema. New columns never go in here — `create(ifNotExists:)`
    /// is a no-op against a database that already exists, so anything added here
    /// would appear on fresh installs only. Put them in `runMigrations()`.
    private func createTables() throws {
        try connection.run(ExerciseTable.table.create(ifNotExists: true) { table in
            table.column(ExerciseTable.id, primaryKey: true)
            table.column(ExerciseTable.name)
            table.column(ExerciseTable.details)
        })

        try connection.run(WorkoutTable.table.create(ifNotExists: true) { table in
            table.column(WorkoutTable.id, primaryKey: true)
            table.column(WorkoutTable.name)
        })

        try connection.run(WorkoutExerciseTable.table.create(ifNotExists: true) { table in
            table.column(WorkoutExerciseTable.workoutId)
            table.column(WorkoutExerciseTable.exerciseId)
            table.column(WorkoutExerciseTable.position)
            table.primaryKey(WorkoutExerciseTable.workoutId, WorkoutExerciseTable.exerciseId)
            table.foreignKey(
                WorkoutExerciseTable.workoutId,
                references: WorkoutTable.table, WorkoutTable.id,
                delete: .cascade
            )
            table.foreignKey(
                WorkoutExerciseTable.exerciseId,
                references: ExerciseTable.table, ExerciseTable.id,
                delete: .cascade
            )
        })

        // No foreign key to `workouts`: deleting a workout must not erase the
        // sessions you already logged against it.
        try connection.run(WorkoutEntryTable.table.create(ifNotExists: true) { table in
            table.column(WorkoutEntryTable.id, primaryKey: true)
            table.column(WorkoutEntryTable.workoutId)
            table.column(WorkoutEntryTable.performedAt)
            table.column(WorkoutEntryTable.caloriesBurnt)
        })

        try connection.run(EntrySetTable.table.create(ifNotExists: true) { table in
            table.column(EntrySetTable.id, primaryKey: true)
            table.column(EntrySetTable.entryId)
            table.column(EntrySetTable.exerciseId)
            table.column(EntrySetTable.position)
            table.column(EntrySetTable.reps)
            table.column(EntrySetTable.weight)
            table.foreignKey(
                EntrySetTable.entryId,
                references: WorkoutEntryTable.table, WorkoutEntryTable.id,
                delete: .cascade
            )
        })

        // Exercise detail reads every set logged against one exercise, which is
        // otherwise a full scan of `entry_sets`.
        try connection.run(
            EntrySetTable.table.createIndex(EntrySetTable.exerciseId, ifNotExists: true)
        )
    }

    /// Runs every migration the database hasn't seen yet, tracked in SQLite's
    /// own `user_version`. Fresh databases start at 0 and run all of them, so
    /// there is one code path regardless of when the database was created.
    private func runMigrations() throws {
        let version = try currentVersion()

        if version < 1 {
            try connection.run(WorkoutEntryTable.table.addColumn(WorkoutEntryTable.startedAt))
            try connection.run(WorkoutEntryTable.table.addColumn(WorkoutEntryTable.healthWorkoutId))
            try connection.run(WorkoutEntryTable.table.addColumn(WorkoutEntryTable.averageHeartRate))
            try connection.run(WorkoutEntryTable.table.addColumn(WorkoutEntryTable.duration))
        }

        guard version < Self.schemaVersion else { return }
        try connection.run("PRAGMA user_version = \(Self.schemaVersion);")
    }

    private func currentVersion() throws -> Int {
        guard let version = try connection.scalar("PRAGMA user_version;") as? Int64 else {
            return 0
        }
        return Int(version)
    }
}
