import SwiftUI

struct RecordExerciseView: View {
    /// Held in `@State` so the instance survives re-renders. SwiftUI re-invokes
    /// the navigationDestination closure that built this view, and a fresh view
    /// model on each pass would wipe whatever the screen had.
    @State private var viewModel: any RecordExerciseViewModelProtocol

    init(viewModel: any RecordExerciseViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section(viewModel.setsSectionTitle) {
                ForEach(viewModel.sets) { set in
                    SetInputRow(
                        setNumber: viewModel.setNumber(forSetId: set.id),
                        weight: .action(
                            viewModel.weightText(forSetId: set.id),
                            { viewModel.didUpdateWeight($0, setId: set.id) }
                        ),
                        reps: .action(
                            viewModel.repsText(forSetId: set.id),
                            { viewModel.didUpdateReps($0, setId: set.id) }
                        )
                    )
                    .deleteDisabled(!viewModel.canRemoveSet)
                }
                .onDelete { offsets in
                    for id in offsets.map({ viewModel.sets[$0].id }) {
                        viewModel.didDeleteSet(id: id)
                    }
                }

                Button {
                    viewModel.didTapAddSet()
                } label: {
                    Label(viewModel.addSetTitle, systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.primaryAccent)
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
                                setNumber: viewModel.setNumberText(forSetId: set.id, in: recording),
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
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
    }
}
