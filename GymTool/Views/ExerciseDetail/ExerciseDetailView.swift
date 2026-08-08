import SwiftUI

struct ExerciseDetailView: View {
    /// Held in `@State` so the instance survives re-renders. SwiftUI re-invokes
    /// the navigationDestination closure that built this view, and a fresh view
    /// model on each pass would wipe whatever the screen had.
    @State private var viewModel: any ExerciseDetailViewModelProtocol

    init(viewModel: any ExerciseDetailViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            Section("NAME") {
                TextField("e.g. Bench Press", text: .action(viewModel.name, viewModel.didUpdateName))
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

            if viewModel.hasRecordings {
                ForEach(viewModel.recordings) { recording in
                    Section(viewModel.sessionTitle(for: recording)) {
                        ForEach(recording.sets) { set in
                            LoggedSetRow(
                                setNumber: viewModel.setNumberText(forSetId: set.id),
                                detail: viewModel.setDetailText(for: set)
                            )
                        }
                    }
                }
            } else {
                Section(viewModel.recordingsSectionTitle) {
                    Text(viewModel.noRecordingsMessage)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            Section {
                Button(viewModel.deleteButtonTitle, role: .destructive) {
                    viewModel.didTapDelete()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .onAppear { viewModel.onAppear() }
    }
}
