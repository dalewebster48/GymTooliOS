import SwiftUI

/// Owns the tab bar, one `NavigationStack` per tab, and the single sheet.
/// Everything the navigator records as state gets presented here.
struct RootView: View {
    @Bindable var navigator: AppNavigator
    let viewFactory: ViewFactory
    /// Passed in rather than built here — see `AppContext.homeContainerViewModel`.
    let homeContainerViewModel: any HomeContainerViewModelProtocol

    var body: some View {
        TabView(selection: $navigator.selectedTab) {
            Tab(
                AppTab.workouts.title,
                systemImage: AppTab.workouts.systemImage,
                value: AppTab.workouts
            ) {
                stack(for: .workouts) {
                    viewFactory.makeWorkoutListView(
                        viewModel: homeContainerViewModel.workoutListViewModel
                    )
                }
            }

            Tab(
                AppTab.exercises.title,
                systemImage: AppTab.exercises.systemImage,
                value: AppTab.exercises
            ) {
                stack(for: .exercises) {
                    viewFactory.makeExerciseListView(
                        viewModel: homeContainerViewModel.exerciseListViewModel
                    )
                }
            }

            Tab(
                AppTab.insights.title,
                systemImage: AppTab.insights.systemImage,
                value: AppTab.insights
            ) {
                stack(for: .insights) {
                    viewFactory.makeHistoryListView(
                        viewModel: homeContainerViewModel.historyListViewModel
                    )
                }
            }
        }
        .sheet(item: $navigator.modal) { route in
            NavigationStack {
                routedView(for: route)
            }
        }
    }

    /// Each tab keeps its own stack, so switching away and back returns you to
    /// where you were rather than to the tab's root.
    private func stack<Root: View>(
        for tab: AppTab,
        @ViewBuilder root: () -> Root
    ) -> some View {
        NavigationStack(path: navigator.path(for: tab)) {
            root()
                .navigationDestination(for: NavigationRoute.self) { route in
                    routedView(for: route)
                }
        }
    }

    /// `.id(route)` ties the screen's SwiftUI identity to the route it came
    /// from. Without it, replacing the route at a given position would reuse
    /// the previous screen's `@State` — and so its view model.
    private func routedView(for route: NavigationRoute) -> some View {
        viewFactory.view(for: route)
            .id(route)
    }
}
