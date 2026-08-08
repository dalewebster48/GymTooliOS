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
                .swipeActions(edge: .trailing) {
                    // Deliberately not destructive — deleting lives inside the
                    // edit screen, behind a confirmation.
                    Button("Edit") {
                        viewModel.didSelectEditWorkout(id: workout.id)
                    }
                    .tint(Theme.primaryAccent)
                }
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
        .onAppear { viewModel.onAppear() }
    }
}
