import SwiftUI

struct ExerciseListView: View {
    let viewModel: any ExerciseListViewModelProtocol

    var body: some View {
        List {
            ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { index, exercise in
                Button {
                    viewModel.didSelectExercise(at: index)
                } label: {
                    ExerciseRow(name: exercise.name, details: exercise.details)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .overlay {
            if viewModel.isEmpty {
                Text(viewModel.emptyStateMessage)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.secondaryText)
                    .padding()
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { viewModel.didTapDone() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.didTapCreateExercise()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear { viewModel.onAppear() }
    }
}
