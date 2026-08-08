import Foundation

protocol HistoryListViewModelProtocol: AnyObject {
    var title: String { get }
    var items: [WorkoutHistoryItem] { get }
    var emptyStateMessage: String { get }
    var isEmpty: Bool { get }
    var deleteConfirmationTitle: String { get }
    var deleteConfirmationMessage: String { get }
    var viewDelegate: (any HistoryListViewModelViewDelegate)? { get set }

    func subtitle(for item: WorkoutHistoryItem) -> String
    func detailText(for item: WorkoutHistoryItem) -> String
    func reload()
    func didSelectItem(at index: Int)
    func didConfirmDeleteItem(at index: Int)
}

protocol HistoryListViewModelViewDelegate: AnyObject {
    func bind(viewModel: any HistoryListViewModelProtocol)
}

final class HistoryListViewModel: HistoryListViewModelProtocol {
    private let workoutEntryService: any WorkoutEntryService
    private let navigator: any Navigator

    weak var viewDelegate: (any HistoryListViewModelViewDelegate)? {
        didSet { reload() }
    }

    let title = "History"
    let deleteConfirmationTitle = "Delete this session?"
    let deleteConfirmationMessage = "The sets you recorded will be removed. This can't be undone."

    var items: [WorkoutHistoryItem] = [] {
        didSet { bind() }
    }

    var emptyStateMessage = "" {
        didSet { bind() }
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    init(
        workoutEntryService: any WorkoutEntryService,
        navigator: any Navigator
    ) {
        self.workoutEntryService = workoutEntryService
        self.navigator = navigator
    }

    func subtitle(for item: WorkoutHistoryItem) -> String {
        item.performedAt.historyFormatted
    }

    func detailText(for item: WorkoutHistoryItem) -> String {
        let exercises = item.exerciseCount == 1 ? "1 exercise" : "\(item.exerciseCount) exercises"
        let sets = item.setCount == 1 ? "1 set" : "\(item.setCount) sets"

        guard let calories = item.caloriesBurnt else {
            return "\(exercises) · \(sets)"
        }
        return "\(exercises) · \(sets) · \(calories) kcal"
    }

    /// Called by the view when the tab becomes visible, so a session logged
    /// while History was off-screen shows up without relaunching.
    func reload() {
        do {
            items = try workoutEntryService.fetchHistory()
            emptyStateMessage = "No workouts logged yet.\nFinish one and it'll show up here."
        } catch {
            items = []
            emptyStateMessage = "Couldn't load your history.\n\(error.localizedDescription)"
        }
    }

    func didSelectItem(at index: Int) {
        guard let item = items[safe: index] else { return }
        navigator.navigate(.push(.historyDetail(entryId: item.entryId)))
    }

    func didConfirmDeleteItem(at index: Int) {
        guard let item = items[safe: index] else { return }

        do {
            try workoutEntryService.deleteEntry(id: item.entryId)
            reload()
        } catch {
            emptyStateMessage = "Couldn't delete that session.\n\(error.localizedDescription)"
        }
    }

    private func bind() {
        Task { @MainActor in
            viewDelegate?.bind(viewModel: self)
        }
    }
}
