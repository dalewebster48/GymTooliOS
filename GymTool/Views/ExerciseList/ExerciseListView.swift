import SwiftUI

struct ExerciseListView: View {
    /// Held in `@State` so the instance survives re-renders. SwiftUI re-invokes
    /// the sheet / navigationDestination closure that built this view, and a
    /// fresh view model on each pass would wipe whatever the screen had.
    @State private var viewModel: any ExerciseListViewModelProtocol

    init(viewModel: any ExerciseListViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            ForEach(viewModel.exercises) { exercise in
                Button {
                    viewModel.didSelectExercise(id: exercise.id)
                } label: {
                    ExerciseRow(name: exercise.name, details: exercise.details)
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
                    viewModel.didTapCreateExercise()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear { viewModel.onAppear() }
    }
}
