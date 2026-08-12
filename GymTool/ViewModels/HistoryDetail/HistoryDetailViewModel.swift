import Foundation
import Observation

@MainActor
protocol HistoryDetailViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var summaryText: String { get }
    var exercises: [LoggedExercise] { get }
    var errorMessage: String? { get }

    /// Apple Health section.
    var healthSectionTitle: String { get }
    var isLinked: Bool { get }
    var isSyncing: Bool { get }
    var canSync: Bool { get }
    var syncButtonTitle: String { get }
    var caloriesText: String? { get }
    var averageHeartRateText: String? { get }
    var durationText: String? { get }
    var healthMessage: String? { get }

    func onAppear()
    func setNumberText(forSetId id: String) -> String
    func setDetailText(for set: WorkoutSet) -> String
    func didTapSync()
}

@Observable
@MainActor
final class HistoryDetailViewModel: HistoryDetailViewModelProtocol {
    @ObservationIgnored private let entryId: String
    @ObservationIgnored private let workoutEntryService: any WorkoutEntryService
    @ObservationIgnored private let healthService: any HealthService

    @ObservationIgnored private var detail: WorkoutHistoryDetail?

    var title = "Session"
    var summaryText = ""
    var exercises: [LoggedExercise] = []
    var errorMessage: String?
    var isSyncing = false
    var healthMessage: String?

    let healthSectionTitle = "APPLE HEALTH"

    var isLinked: Bool {
        detail?.isLinked ?? false
    }

    var canSync: Bool {
        !isSyncing && detail != nil && healthService.isAvailable
    }

    var syncButtonTitle: String {
        isLinked ? "Re-sync with Apple Health" : "Sync with Apple Health"
    }

    var caloriesText: String? {
        guard let calories = detail?.caloriesBurnt else { return nil }
        return "\(calories) kcal"
    }

    var averageHeartRateText: String? {
        guard let rate = detail?.averageHeartRate else { return nil }
        return "\(Int(rate.rounded())) bpm"
    }

    var durationText: String? {
        guard let duration = detail?.duration else { return nil }
        let minutes = Int((duration / 60).rounded())
        return minutes == 1 ? "1 min" : "\(minutes) min"
    }

    init(
        entryId: String,
        workoutEntryService: any WorkoutEntryService,
        healthService: any HealthService
    ) {
        self.entryId = entryId
        self.workoutEntryService = workoutEntryService
        self.healthService = healthService
    }

    func onAppear() {
        loadDetail()
    }

    func setNumberText(forSetId id: String) -> String {
        for exercise in exercises {
            if let position = exercise.sets.firstIndex(where: { $0.id == id }) {
                return "Set \(position + 1)"
            }
        }
        return ""
    }

    func setDetailText(for set: WorkoutSet) -> String {
        guard set.weight > 0 else { return "\(set.reps) reps" }
        return "\(set.reps) reps × \(set.weight.formattedWeight) kg"
    }

    func didTapSync() {
        guard let detail, !isSyncing else { return }

        isSyncing = true
        healthMessage = nil

        Task {
            defer { isSyncing = false }

            do {
                guard let workout = try await healthService.fetchWorkout(
                    startingAt: detail.healthSearchAnchor
                ) else {
                    // HealthKit never reports whether read access was granted,
                    // so "declined" and "nothing recorded" look identical here.
                    // The copy has to cover both.
                    healthMessage = "No Apple Health workout found for this session. If you recorded one, check GymTool's access under Settings › Health."
                    return
                }

                try workoutEntryService.linkHealthWorkout(
                    entryId: entryId,
                    healthWorkout: workout
                )
                loadDetail()
            } catch {
                healthMessage = "Couldn't sync with Apple Health. \(error.localizedDescription)"
            }
        }
    }

    private func loadDetail() {
        do {
            guard let detail = try workoutEntryService.fetchHistoryDetail(entryId: entryId) else {
                errorMessage = "That session no longer exists."
                return
            }
            self.detail = detail
            title = detail.workoutName
            exercises = detail.exercises
            summaryText = Self.makeSummary(for: detail)
        } catch {
            errorMessage = "Couldn't load this session. \(error.localizedDescription)"
        }
    }

    private static func makeSummary(for detail: WorkoutHistoryDetail) -> String {
        detail.performedAt.historyFormatted
    }
}
