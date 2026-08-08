import SwiftUI

struct WorkoutListView: View {
    let viewModel: any WorkoutListViewModelProtocol

    var body: some View {
        List {
            ForEach(viewModel.workouts) { workout in
                Button {
                    viewModel.didSelectWorkout(id: workout.id)
                } label: {
                    WorkoutRow(
                        name: workout.name,
                        subtitle: viewModel.subtitle(for: workout)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .overlay {
            if viewModel.isEmpty {
                Text(viewModel.emptyStateMessage)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)
                    .padding()
            }
        }
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.didTapCreateWorkout()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear { viewModel.onAppear() }
    }
}
