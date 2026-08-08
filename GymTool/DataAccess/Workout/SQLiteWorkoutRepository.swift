import Foundation
import SQLite

final class SQLiteWorkoutRepository: WorkoutRepository {
    private let databaseProvider: any DatabaseProvider

    init(databaseProvider: any DatabaseProvider) {
        self.databaseProvider = databaseProvider
    }

    func fetchAll() throws -> [Workout] {
        let exercisesByWorkout = try loadExercisesByWorkout(workoutId: nil)
        let query = WorkoutTable.table.order(WorkoutTable.name.asc)

        return try databaseProvider.connection.prepare(query).map { row in
            let id = row[WorkoutTable.id]
            return Workout(
                id: id,
                name: row[WorkoutTable.name],
                exercises: exercisesByWorkout[id] ?? []
            )
        }
    }

    func fetch(id: String) throws -> Workout? {
        let query = WorkoutTable.table.filter(WorkoutTable.id == id)
        guard let row = try databaseProvider.connection.pluck(query) else { return nil }

        let exercisesByWorkout = try loadExercisesByWorkout(workoutId: id)
        return Workout(
            id: id,
            name: row[WorkoutTable.name],
            exercises: exercisesByWorkout[id] ?? []
        )
    }

    func insert(_ workout: Workout) throws {
        let connection = databaseProvider.connection

        try connection.transaction {
            try connection.run(
                WorkoutTable.table.insert(
                    WorkoutTable.id <- workout.id,
                    WorkoutTable.name <- workout.name
                )
            )

            for (position, exercise) in workout.exercises.enumerated() {
                try connection.run(
                    WorkoutExerciseTable.table.insert(
                        WorkoutExerciseTable.workoutId <- workout.id,
                        WorkoutExerciseTable.exerciseId <- exercise.id,
                        WorkoutExerciseTable.position <- position
                    )
                )
            }
        }
    }

    func update(_ workout: Workout) throws {
        let connection = databaseProvider.connection

        try connection.transaction {
            try connection.run(
                WorkoutTable.table
                    .filter(WorkoutTable.id == workout.id)
                    .update(WorkoutTable.name <- workout.name)
            )

            // Replacing the join rows wholesale handles additions, removals and
            // reordering in one step, rather than diffing three cases.
            try connection.run(
                WorkoutExerciseTable.table
                    .filter(WorkoutExerciseTable.workoutId == workout.id)
                    .delete()
            )

            for (position, exercise) in workout.exercises.enumerated() {
                try connection.run(
                    WorkoutExerciseTable.table.insert(
                        WorkoutExerciseTable.workoutId <- workout.id,
                        WorkoutExerciseTable.exerciseId <- exercise.id,
                        WorkoutExerciseTable.position <- position
                    )
                )
            }
        }
    }

    func delete(id: String) throws {
        // `workout_exercises` cascades off this delete. `workout_entries` does
        // not — logged sessions outlive the workout they were performed from.
        let row = WorkoutTable.table.filter(WorkoutTable.id == id)
        try databaseProvider.connection.run(row.delete())
    }

    /// Loads the ordered exercises for every workout, or for a single workout
    /// when `workoutId` is supplied. Doing this in one query keeps `fetchAll`
    /// to two round-trips regardless of how many workouts exist.
    private func loadExercisesByWorkout(workoutId: String?) throws -> [String: [Exercise]] {
        var query = WorkoutExerciseTable.table
            .join(
                ExerciseTable.table,
                on: ExerciseTable.table[ExerciseTable.id] == WorkoutExerciseTable.exerciseId
            )
            .order(WorkoutExerciseTable.position.asc)

        if let workoutId {
            query = query.filter(WorkoutExerciseTable.workoutId == workoutId)
        }

        var exercisesByWorkout: [String: [Exercise]] = [:]
        for row in try databaseProvider.connection.prepare(query) {
            let workoutId = row[WorkoutExerciseTable.workoutId]
            exercisesByWorkout[workoutId, default: []].append(Exercise(joinedRow: row))
        }
        return exercisesByWorkout
    }
}
