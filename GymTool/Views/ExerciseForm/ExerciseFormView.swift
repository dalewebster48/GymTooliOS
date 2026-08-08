import SwiftUI

struct ExerciseFormView: View {
    let viewModel: any ExerciseFormViewModelProtocol

    @FocusState private var isNameFocused: Bool

    var body: some View {
        Form {
            Section("NAME") {
                TextField("e.g. Bench Press", text: Binding(
                    get: { viewModel.name },
                    set: { viewModel.didUpdateName($0) }
                ))
                .focused($isNameFocused)
            }

            Section("DESCRIPTION") {
                TextEditor(text: Binding(
                    get: { viewModel.details },
                    set: { viewModel.didUpdateDetails($0) }
                ))
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
        .onAppear { isNameFocused = true }
    }
}
