import SwiftUI

struct WorkoutFormView: View {
    /// Held in `@State` so the instance survives re-renders. SwiftUI re-invokes
    /// the sheet / navigationDestination closure that built this view, and a
    /// fresh view model on each pass would wipe whatever the screen had.
    @State private var viewModel: any WorkoutFormViewModelProtocol

    init(viewModel: any WorkoutFormViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

    @FocusState private var isNameFocused: Bool

    var body: some View {
        Form {
            Section("WORKOUT NAME") {
                TextField("e.g. Push Day", text: .action(viewModel.name, viewModel.didUpdateName))
                .focused($isNameFocused)
            }

            Section("EXERCISES — TAP IN THE ORDER YOU'LL DO THEM") {
                if viewModel.hasExercises {
                    ForEach(viewModel.exercises) { exercise in
                        Button {
                            viewModel.didToggleExercise(id: exercise.id)
                        } label: {
                            ExerciseSelectionRow(
                                name: exercise.name,
                                details: exercise.details,
                                selectionOrder: viewModel.selectionOrder(forExerciseId: exercise.id)
                            )
                        }
                        .buttonStyle(.plain)
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

            if viewModel.canDelete {
                Section {
                    Button(viewModel.deleteButtonTitle, role: .destructive) {
                        isNameFocused = false
                        viewModel.didTapDelete()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { viewModel.didTapCancel() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { viewModel.didTapSave() }
                    .disabled(!viewModel.canSave)
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
        .onAppear {
            viewModel.onAppear()
            isNameFocused = true
        }
    }
}
