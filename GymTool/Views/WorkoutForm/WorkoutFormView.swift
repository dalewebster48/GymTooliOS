import SwiftUI

struct WorkoutFormView: View {
    let viewModel: any WorkoutFormViewModelProtocol

    @FocusState private var isNameFocused: Bool

    var body: some View {
        Form {
            Section("WORKOUT NAME") {
                TextField("e.g. Push Day", text: Binding(
                    get: { viewModel.name },
                    set: { viewModel.didUpdateName($0) }
                ))
                .focused($isNameFocused)
            }

            Section("EXERCISES — TAP IN THE ORDER YOU'LL DO THEM") {
                if viewModel.hasExercises {
                    ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                        Button {
                            viewModel.didToggleExercise(at: index)
                        } label: {
                            ExerciseSelectionRow(
                                name: exercise.name,
                                details: exercise.details,
                                selectionOrder: viewModel.selectionOrder(at: index)
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
            isPresented: Binding(
                get: { viewModel.isConfirmingDelete },
                set: { if !$0 { viewModel.didCancelDelete() } }
            ),
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
