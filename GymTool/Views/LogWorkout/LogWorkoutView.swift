import SwiftUI

struct LogWorkoutView: View {
    let viewModel: any LogWorkoutViewModelProtocol

    var body: some View {
        List {
            ForEach(Array(viewModel.exerciseViewModels.enumerated()), id: \.element.exerciseId) { exerciseIndex, exerciseViewModel in
                Section {
                    ForEach(Array(exerciseViewModel.sets.enumerated()), id: \.element.id) { setIndex, _ in
                        SetInputRow(
                            setNumber: setIndex + 1,
                            reps: Binding(
                                get: { exerciseViewModel.repsText(at: setIndex) },
                                set: { viewModel.didUpdateReps($0, setIndex: setIndex, exerciseIndex: exerciseIndex) }
                            ),
                            weight: Binding(
                                get: { exerciseViewModel.weightText(at: setIndex) },
                                set: { viewModel.didUpdateWeight($0, setIndex: setIndex, exerciseIndex: exerciseIndex) }
                            )
                        )
                        // A workout always keeps at least one set.
                        .deleteDisabled(exerciseViewModel.sets.count <= 1)
                    }
                    .onDelete { offsets in
                        guard let setIndex = offsets.first else { return }
                        viewModel.didDeleteSet(setIndex: setIndex, exerciseIndex: exerciseIndex)
                    }
                } header: {
                    Text(exerciseViewModel.exerciseName)
                } footer: {
                    Button {
                        viewModel.didTapAddSet(inExerciseAt: exerciseIndex)
                    } label: {
                        Label("Add Set", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.primaryAccent)
                    .padding(.vertical, 8)
                }
            }

            Section {
                SessionSummaryView(calories: Binding(
                    get: { viewModel.caloriesText },
                    set: { viewModel.didUpdateCalories($0) }
                ))
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
}
