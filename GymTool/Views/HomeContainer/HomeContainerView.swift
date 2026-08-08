import SwiftUI

struct HomeContainerView: View {
    let viewModel: any HomeContainerViewModelProtocol

    var body: some View {
        TabView(selection: selectedTabBinding) {
            WorkoutListView(viewModel: viewModel.workoutListViewModel)
                .tag(HomeTab.workouts)

            HistoryListView(viewModel: viewModel.historyListViewModel)
                .tag(HomeTab.history)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Theme.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: selectedTabBinding) {
                    ForEach(viewModel.tabs, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }

            // The container owns the bar, and the Workouts tab is the only one
            // that contributes items — mirroring the UIKit `HomeTabContent`
            // delegation this replaces.
            if viewModel.showsWorkoutActions {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Manage") { viewModel.didTapManageExercises() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.didTapCreateWorkout()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private var selectedTabBinding: Binding<HomeTab> {
        Binding(
            get: { viewModel.selectedTab },
            set: { viewModel.didSelectTab(at: $0.rawValue) }
        )
    }
}
