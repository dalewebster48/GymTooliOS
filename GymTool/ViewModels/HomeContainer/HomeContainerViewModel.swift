import Foundation
import Observation

/// The tab roots are vended by `ViewModelFactory` like every other view model
/// — never constructed inline here.
@MainActor
protocol HomeContainerChildViewModelFactory: AnyObject {
    func makeWorkoutListViewModel() -> any WorkoutListViewModelProtocol
    func makeExerciseListViewModel() -> any ExerciseListViewModelProtocol
    func makeHistoryListViewModel() -> any HistoryListViewModelProtocol
}

/// Owns the three tab-root view models for the life of the app. Tab *selection*
/// is not here — it lives on `AppNavigator`, because a push has to know which
/// stack it lands on.
@MainActor
protocol HomeContainerViewModelProtocol: AnyObject, Observable {
    var workoutListViewModel: any WorkoutListViewModelProtocol { get }
    var exerciseListViewModel: any ExerciseListViewModelProtocol { get }
    var historyListViewModel: any HistoryListViewModelProtocol { get }

    func onAppear()
}

@Observable
@MainActor
final class HomeContainerViewModel: HomeContainerViewModelProtocol {
    @ObservationIgnored let workoutListViewModel: any WorkoutListViewModelProtocol
    @ObservationIgnored let exerciseListViewModel: any ExerciseListViewModelProtocol
    @ObservationIgnored let historyListViewModel: any HistoryListViewModelProtocol

    @ObservationIgnored private let healthLinkReminderService: any HealthLinkReminderService
    @ObservationIgnored private let navigator: any Navigator

    init(
        childViewModelFactory: any HomeContainerChildViewModelFactory,
        healthLinkReminderService: any HealthLinkReminderService,
        navigator: any Navigator
    ) {
        self.workoutListViewModel = childViewModelFactory.makeWorkoutListViewModel()
        self.exerciseListViewModel = childViewModelFactory.makeExerciseListViewModel()
        self.historyListViewModel = childViewModelFactory.makeHistoryListViewModel()
        self.healthLinkReminderService = healthLinkReminderService
        self.navigator = navigator
    }

    func onAppear() {
        healthLinkReminderService.addConsumer(self)

        // A reminder that cold-launched the app was tapped before this existed.
        if let entryId = healthLinkReminderService.takeOpenedEntryId() {
            showSession(entryId: entryId)
        }
    }

    private func showSession(entryId: String) {
        navigator.navigate(.reveal(.insights, .historyDetail(entryId: entryId)))
    }
}

// MARK: - HealthLinkReminderConsumer

extension HomeContainerViewModel: HealthLinkReminderConsumer {
    nonisolated func reminderWasOpened(
        healthLinkReminderService: any HealthLinkReminderService,
        entryId: String
    ) {
        Task { @MainActor in showSession(entryId: entryId) }
    }
}
