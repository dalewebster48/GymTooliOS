import Foundation
import Observation

@MainActor
protocol HistoryDetailViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var summaryText: String { get }
    var exercises: [LoggedExercise] { get }
    var errorMessage: String? { get }

    func onAppear()
    func setNumberText(at index: Int) -> String
    func setDetailText(for set: WorkoutSet) -> String
}

@Observable
@MainActor
final class HistoryDetailViewModel: HistoryDetailViewModelProtocol {
    @ObservationIgnored private let entryId: String
    @ObservationIgnored private let workoutEntryService: any WorkoutEntryService

    var title = "Session"
    var summaryText = ""
    var exercises: [LoggedExercise] = []
    var errorMessage: String?

    init(
        entryId: String,
        workoutEntryService: any WorkoutEntryService
    ) {
        self.entryId = entryId
        self.workoutEntryService = workoutEntryService
    }

    func onAppear() {
        loadDetail()
    }

    func setNumberText(at index: Int) -> String {
        "Set \(index + 1)"
    }

    func setDetailText(for set: WorkoutSet) -> String {
        guard set.weight > 0 else { return "\(set.reps) reps" }
        return "\(set.reps) reps × \(set.weight.formattedWeight) kg"
    }

    private func loadDetail() {
        do {
            guard let detail = try workoutEntryService.fetchHistoryDetail(entryId: entryId) else {
                errorMessage = "That session no longer exists."
                return
            }
            title = detail.workoutName
            exercises = detail.exercises
            summaryText = Self.makeSummary(for: detail)
        } catch {
            errorMessage = "Couldn't load this session. \(error.localizedDescription)"
        }
    }

    private static func makeSummary(for detail: WorkoutHistoryDetail) -> String {
        guard let calories = detail.caloriesBurnt else {
            return detail.performedAt.historyFormatted
        }
        return "\(detail.performedAt.historyFormatted) · \(calories) kcal"
    }
}
