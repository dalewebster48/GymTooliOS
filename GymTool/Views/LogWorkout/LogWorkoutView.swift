import SwiftUI

struct LogWorkoutView: View {
    /// Held in `@State` so the instance survives re-renders. SwiftUI re-invokes
    /// the sheet / navigationDestination closure that built this view, and a
    /// fresh view model on each pass would wipe whatever the screen had.
    @State private var viewModel: any LogWorkoutViewModelProtocol

    init(viewModel: any LogWorkoutViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section(viewModel.exercisesSectionTitle) {
                ForEach(viewModel.exercises) { exercise in
                    Button {
                        viewModel.didSelectExercise(id: exercise.exerciseId)
                    } label: {
                        ExerciseRow(
                            name: exercise.name,
                            details: viewModel.progressText(for: exercise)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                SessionSummaryView(
                    calories: .action(viewModel.caloriesText, viewModel.didUpdateCalories)
                )
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(Theme.destructive)
                }
            }

            Section {
                Button(viewModel.discardButtonTitle, role: .destructive) {
                    viewModel.didTapDiscard()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { viewModel.didTapCancel() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Submit") { viewModel.didTapSubmit() }
                    .disabled(!viewModel.canSubmit)
                    .fontWeight(.semibold)
            }
        }
        .confirmationDialog(
            viewModel.discardConfirmationTitle,
            isPresented: .presented(viewModel.isConfirmingDiscard, onDismiss: viewModel.didCancelDiscard),
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { viewModel.didConfirmDiscard() }
            Button("Cancel", role: .cancel) { viewModel.didCancelDiscard() }
        } message: {
            Text(viewModel.discardConfirmationMessage)
        }
        .onAppear { viewModel.onAppear() }
    }
}
