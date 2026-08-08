import SwiftUI

struct WorkoutDetailView: View {
    /// Held in `@State` so the instance survives re-renders. SwiftUI re-invokes
    /// the navigationDestination closure that built this view, and a fresh view
    /// model on each pass would wipe whatever the screen had.
    @State private var viewModel: any WorkoutDetailViewModelProtocol

    init(viewModel: any WorkoutDetailViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Button {
                    viewModel.didTapLogWorkout()
                } label: {
                    Label(viewModel.logButtonTitle, systemImage: "play.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.primaryAccent)
                .padding(.vertical, 4)
            }

            Section(viewModel.exercisesSectionTitle) {
                if viewModel.hasExercises {
                    ForEach(viewModel.exercises) { exercise in
                        ExerciseRow(
                            name: exercise.name,
                            details: viewModel.detailText(for: exercise)
                        )
                    }
                } else {
                    Text(viewModel.emptyStateMessage)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(Theme.destructive)
                }
            }

            Section {
                Button(viewModel.deleteButtonTitle, role: .destructive) {
                    viewModel.didTapDelete()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { viewModel.didTapEdit() }
            }
        }
        .confirmationDialog(
            viewModel.deleteConfirmationTitle,
            isPresented: .presented(viewModel.isConfirmingDelete, onDismiss: viewModel.didCancelDelete),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { viewModel.didConfirmDelete() }
            Button("Cancel", role: .cancel) { viewModel.didCancelDelete() }
        } message: {
            Text(viewModel.deleteConfirmationMessage)
        }
        .onAppear { viewModel.onAppear() }
    }
}
