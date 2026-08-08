import SwiftUI

struct ExerciseFormView: View {
    /// Held in `@State` so the instance survives re-renders. SwiftUI re-invokes
    /// the sheet / navigationDestination closure that built this view, and a
    /// fresh view model on each pass would wipe whatever the screen had.
    @State private var viewModel: any ExerciseFormViewModelProtocol

    init(viewModel: any ExerciseFormViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

    @FocusState private var isNameFocused: Bool

    var body: some View {
        Form {
            Section("NAME") {
                TextField("e.g. Bench Press", text: .action(viewModel.name, viewModel.didUpdateName))
                .focused($isNameFocused)
            }

            Section("DESCRIPTION") {
                TextEditor(text: .action(viewModel.details, viewModel.didUpdateDetails))
                .frame(minHeight: 100)
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
        .onAppear { isNameFocused = true }
    }
}
