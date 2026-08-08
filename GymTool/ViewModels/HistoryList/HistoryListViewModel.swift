import Foundation
import Observation

@MainActor
protocol HistoryListViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var items: [WorkoutHistoryItem] { get }
    var emptyStateMessage: String { get }
    var isEmpty: Bool { get }
    var deleteConfirmationTitle: String { get }
    var deleteConfirmationMessage: String { get }
    var isConfirmingDelete: Bool { get }

    func onAppear()
    func subtitle(for item: WorkoutHistoryItem) -> String
    func detailText(for item: WorkoutHistoryItem) -> String
    func reload()
    func didSelectItem(at index: Int)
    func didRequestDeleteItem(at index: Int)
    func didConfirmDelete()
    func didCancelDelete()
}

@Observable
@MainActor
final class HistoryListViewModel: HistoryListViewModelProtocol {
    @ObservationIgnored private let workoutEntryService: any WorkoutEntryService
    @ObservationIgnored private let navigator: any Navigator

    let title = "History"
    let deleteConfirmationTitle = "Delete this session?"
    let deleteConfirmationMessage = "The sets you recorded will be removed. This can't be undone."

    var items: [WorkoutHistoryItem] = []
    var emptyStateMessage = ""

    /// The row a delete has been requested for. The view only asks whether a
    /// confirmation is showing; which row it applies to stays in here.
    private var pendingDeleteIndex: Int?

    var isConfirmingDelete: Bool {
        pendingDeleteIndex != nil
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

        // A session logged from the Workouts tab has to appear here without the
        // view needing an appearance hook to notice.
        workoutEntryService.addConsumer(self)
    }

    func onAppear() {
        reload()
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

    func didRequestDeleteItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        pendingDeleteIndex = index
    }

    func didCancelDelete() {
        pendingDeleteIndex = nil
    }

    func didConfirmDelete() {
        defer { pendingDeleteIndex = nil }
        guard let index = pendingDeleteIndex, let item = items[safe: index] else { return }

        do {
            try workoutEntryService.deleteEntry(id: item.entryId)
        } catch {
            emptyStateMessage = "Couldn't delete that session.\n\(error.localizedDescription)"
        }
    }
}

// MARK: - WorkoutEntryServiceConsumer

extension HistoryListViewModel: WorkoutEntryServiceConsumer {
    nonisolated func entriesDidChange(workoutEntryService: any WorkoutEntryService) {
        Task { @MainActor in reload() }
    }
}
