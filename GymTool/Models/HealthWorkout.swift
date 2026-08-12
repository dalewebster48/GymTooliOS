import Foundation

/// A workout recorded by Apple Health, reduced to the metrics GymTool shows.
/// HealthKit has no concept of sets, reps or weight — those stay ours.
struct HealthWorkout: Identifiable, Hashable {
    let id: UUID
    let startDate: Date
    let duration: TimeInterval
    let activeEnergyBurned: Int?
    let averageHeartRate: Double?
}
