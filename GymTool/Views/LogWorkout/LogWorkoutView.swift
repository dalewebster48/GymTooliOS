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
            ForEach(viewModel.exerciseViewModels, id: \.exerciseId) { exerciseViewModel in
                exerciseSection(exerciseViewModel)
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
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { viewModel.didTapCancel() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Submit") { viewModel.didTapSubmit() }
                    .disabled(!viewModel.canSubmit)
                    .fontWeight(.semibold)
            }
        }
        .onAppear { viewModel.onAppear() }
    }

    @ViewBuilder
    private func exerciseSection(
        _ exerciseViewModel: any LogWorkoutExerciseViewModelProtocol
    ) -> some View {
        let exerciseId = exerciseViewModel.exerciseId

        Section {
            ForEach(exerciseViewModel.sets) { set in
                SetInputRow(
                    setNumber: exerciseViewModel.setNumber(forSetId: set.id),
                    reps: .action(
                        exerciseViewModel.repsText(forSetId: set.id),
                        { viewModel.didUpdateReps($0, setId: set.id, exerciseId: exerciseId) }
                    ),
                    weight: .action(
                        exerciseViewModel.weightText(forSetId: set.id),
                        { viewModel.didUpdateWeight($0, setId: set.id, exerciseId: exerciseId) }
                    )
                )
                .deleteDisabled(!exerciseViewModel.canRemoveSet)
            }
            .onDelete { offsets in
                let ids = offsets.map { exerciseViewModel.sets[$0].id }
                for id in ids {
                    viewModel.didDeleteSet(setId: id, exerciseId: exerciseId)
                }
            }
        } header: {
            Text(exerciseViewModel.exerciseName)
        } footer: {
            Button {
                viewModel.didTapAddSet(exerciseId: exerciseId)
            } label: {
                Label("Add Set", systemImage: "plus.circle.fill")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.primaryAccent)
            .padding(.vertical, 8)
        }
    }
}
