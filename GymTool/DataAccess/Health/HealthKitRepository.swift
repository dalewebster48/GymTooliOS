import Foundation
import HealthKit

final class HealthKitRepository: HealthRepository {
    /// A workout logged in GymTool is assumed to have a matching Watch workout
    /// started within this window.
    private static let searchWindow: TimeInterval = 5 * 60 * 60

    /// How far before the session's start to look, covering the gap between
    /// starting the workout on the Watch and opening GymTool to log it.
    private static let leadIn: TimeInterval = 60 * 60

    private let healthStore = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
        ]
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else { throw HealthError.unavailable }
        // Nothing is shared back to Health, so the write set is empty.
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchWorkout(startingAt start: Date) async throws -> HealthWorkout? {
        guard isAvailable else { throw HealthError.unavailable }

        // No `.strictStartDate`: the default matches any workout overlapping the
        // window, which is what's wanted. You typically start the workout on the
        // Watch and *then* open GymTool, so its start is usually a little before
        // the session's — strict containment would miss it every time.
        let predicate = HKQuery.predicateForSamples(
            withStart: start.addingTimeInterval(-Self.leadIn),
            end: start.addingTimeInterval(Self.searchWindow)
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)],
            // A session is expected to match one workout. Asking for a couple
            // means an unexpected second one is ignored rather than picked.
            limit: 2
        )

        let workouts = try await descriptor.result(for: healthStore)
        guard let workout = workouts.first else { return nil }

        return HealthWorkout(
            id: workout.uuid,
            startDate: workout.startDate,
            duration: workout.duration,
            activeEnergyBurned: Self.activeEnergyBurned(from: workout),
            averageHeartRate: Self.averageHeartRate(from: workout)
        )
    }

    /// `totalEnergyBurned` is deprecated in favour of per-type statistics.
    private static func activeEnergyBurned(from workout: HKWorkout) -> Int? {
        guard let quantity = workout
            .statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()
        else { return nil }

        return Int(quantity.doubleValue(for: .kilocalorie()))
    }

    private static func averageHeartRate(from workout: HKWorkout) -> Double? {
        guard let quantity = workout
            .statistics(for: HKQuantityType(.heartRate))?
            .averageQuantity()
        else { return nil }

        return quantity.doubleValue(for: .count().unitDivided(by: .minute()))
    }
}
