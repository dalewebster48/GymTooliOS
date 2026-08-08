import Foundation
import Observation

enum HomeTab: Int, CaseIterable, Hashable {
    case workouts
    case history

    var title: String {
        switch self {
        case .workouts: "Workouts"
        case .history: "History"
        }
    }
}

/// The home screen vends the two tab view models it pages between. They are
/// built by `ViewModelFactory` like every other view model — never inline here.
@MainActor
protocol HomeContainerChildViewModelFactory: AnyObject {
    func makeWorkoutListViewModel() -> any WorkoutListViewModelProtocol
    func makeHistoryListViewModel() -> any HistoryListViewModelProtocol
}

@MainActor
protocol HomeContainerViewModelProtocol: AnyObject, Observable {
    var tabs: [HomeTab] { get }
    var selectedTab: HomeTab { get }
    var workoutListViewModel: any WorkoutListViewModelProtocol { get }
    var historyListViewModel: any HistoryListViewModelProtocol { get }
    /// Only the Workouts tab contributes bar buttons; History has none.
    var showsWorkoutActions: Bool { get }

    func didSelectTab(at index: Int)
    /// Called when the user swipes between pages, so the segmented control
    /// follows the page rather than the other way round.
    func didPageTo(index: Int)
    func didTapCreateWorkout()
    func didTapManageExercises()
}

@Observable
@MainActor
final class HomeContainerViewModel: HomeContainerViewModelProtocol {
    let tabs = HomeTab.allCases

    @ObservationIgnored let workoutListViewModel: any WorkoutListViewModelProtocol
    @ObservationIgnored let historyListViewModel: any HistoryListViewModelProtocol

    var selectedTab: HomeTab = .workouts

    var showsWorkoutActions: Bool {
        selectedTab == .workouts
    }

    init(childViewModelFactory: any HomeContainerChildViewModelFactory) {
        self.workoutListViewModel = childViewModelFactory.makeWorkoutListViewModel()
        self.historyListViewModel = childViewModelFactory.makeHistoryListViewModel()
    }

    func didSelectTab(at index: Int) {
        guard let tab = HomeTab(rawValue: index) else { return }
        selectedTab = tab
    }

    func didPageTo(index: Int) {
        guard let tab = HomeTab(rawValue: index) else { return }
        selectedTab = tab
    }

    // The container owns the toolbar, so it forwards the Workouts tab's actions
    // rather than the view reaching into a child view model itself.
    func didTapCreateWorkout() {
        workoutListViewModel.didTapCreateWorkout()
    }

    func didTapManageExercises() {
        workoutListViewModel.didTapManageExercises()
    }
}
