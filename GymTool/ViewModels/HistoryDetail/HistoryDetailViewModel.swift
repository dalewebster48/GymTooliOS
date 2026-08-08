import Foundation

protocol HistoryDetailViewModelProtocol: AnyObject {
    var title: String { get }
    var summaryText: String { get }
    var exercises: [LoggedExercise] { get }
    var errorMessage: String? { get }
    var viewDelegate: (any HistoryDetailViewModelViewDelegate)? { get set }

    func setNumberText(at index: Int) -> String
    func setDetailText(for set: WorkoutSet) -> String
}

protocol HistoryDetailViewModelViewDelegate: AnyObject {
    func bind(viewModel: any HistoryDetailViewModelProtocol)
}

final class HistoryDetailViewModel: HistoryDetailViewModelProtocol {
    private let entryId: String
    private let workoutEntryService: any WorkoutEntryService

    weak var viewDelegate: (any HistoryDetailViewModelViewDelegate)? {
        didSet { loadDetail() }
    }

    var title = "Session" {
        didSet { bind() }
    }

    var summaryText = "" {
        didSet { bind() }
    }

    var exercises: [LoggedExercise] = [] {
        didSet { bind() }
    }

    var errorMessage: String? {
        didSet { bind() }
    }

    init(
        entryId: String,
        workoutEntryService: any WorkoutEntryService
    ) {
        self.entryId = entryId
        self.workoutEntryService = workoutEntryService
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

    private func bind() {
        Task { @MainActor in
            viewDelegate?.bind(viewModel: self)
        }
    }
}
