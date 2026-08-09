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
    /// A workout left part-way through, offered at the top of the list.
    var resumableSession: WorkoutSession? { get }
    var resumeSectionTitle: String { get }
    var resumeSubtitle: String { get }

    func onAppear()
    func didTapResumeSession()
    func subtitle(for item: WorkoutHistoryItem) -> String
    func detailText(for item: WorkoutHistoryItem) -> String
    func reload()
    func didSelectItem(id: String)
    func didRequestDeleteItem(id: String)
    func didConfirmDelete()
    func didCancelDelete()
}

@Observable
@MainActor
final class HistoryListViewModel: HistoryListViewModelProtocol {
    @ObservationIgnored private let workoutEntryService: any WorkoutEntryService
    @ObservationIgnored private let workoutSessionService: any WorkoutSessionService
    @ObservationIgnored private let navigator: any Navigator

    let title = "History"
    let resumeSectionTitle = "IN PROGRESS"
    let deleteConfirmationTitle = "Delete this session?"
    let deleteConfirmationMessage = "The sets you recorded will be removed. This can't be undone."

    var items: [WorkoutHistoryItem] = []
    var emptyStateMessage = ""
    var resumableSession: WorkoutSession?

    var resumeSubtitle: String {
        guard let resumableSession else { return "" }
        return "Started \(resumableSession.startedAt.historyFormatted)"
    }

    /// The entry a delete has been requested for. The view only asks whether a
    /// confirmation is showing; which entry it applies to stays in here. Held
    /// by id rather than index so a refresh mid-confirmation can't retarget it.
    private var pendingDeleteEntryId: String?

    var isConfirmingDelete: Bool {
        pendingDeleteEntryId != nil
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    init(
        workoutEntryService: any WorkoutEntryService,
        workoutSessionService: any WorkoutSessionService,
        navigator: any Navigator
    ) {
        self.workoutEntryService = workoutEntryService
        self.workoutSessionService = workoutSessionService
        self.navigator = navigator

        // A session logged from the Workouts tab has to appear here without the
        // view needing an appearance hook to notice.
        workoutEntryService.addConsumer(self)
        workoutSessionService.addConsumer(self)
    }

    func onAppear() {
        reload()
        readSession()
    }

    /// Reopens the logging sheet, which resumes rather than restarts.
    func didTapResumeSession() {
        guard let resumableSession else { return }
        navigator.navigate(.modal(.logWorkout(workoutId: resumableSession.workoutId)))
    }

    private func readSession() {
        resumableSession = workoutSessionService.currentSession
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

    func didSelectItem(id: String) {
        guard items.contains(where: { $0.entryId == id }) else { return }
        navigator.navigate(.push(.historyDetail(entryId: id)))
    }

    func didRequestDeleteItem(id: String) {
        guard items.contains(where: { $0.entryId == id }) else { return }
        pendingDeleteEntryId = id
    }

    func didCancelDelete() {
        pendingDeleteEntryId = nil
    }

    func didConfirmDelete() {
        defer { pendingDeleteEntryId = nil }
        guard let entryId = pendingDeleteEntryId else { return }

        do {
            try workoutEntryService.deleteEntry(id: entryId)
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

// MARK: - WorkoutSessionConsumer

extension HistoryListViewModel: WorkoutSessionConsumer {
    nonisolated func sessionDidChange(workoutSessionService: any WorkoutSessionService) {
        Task { @MainActor in readSession() }
    }
}
