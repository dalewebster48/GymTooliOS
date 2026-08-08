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
}

@Observable
@MainActor
final class HomeContainerViewModel: HomeContainerViewModelProtocol {
    @ObservationIgnored let workoutListViewModel: any WorkoutListViewModelProtocol
    @ObservationIgnored let exerciseListViewModel: any ExerciseListViewModelProtocol
    @ObservationIgnored let historyListViewModel: any HistoryListViewModelProtocol

    init(childViewModelFactory: any HomeContainerChildViewModelFactory) {
        self.workoutListViewModel = childViewModelFactory.makeWorkoutListViewModel()
        self.exerciseListViewModel = childViewModelFactory.makeExerciseListViewModel()
        self.historyListViewModel = childViewModelFactory.makeHistoryListViewModel()
    }
}
