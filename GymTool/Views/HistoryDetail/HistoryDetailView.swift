import SwiftUI

struct HistoryDetailView: View {
    let viewModel: any HistoryDetailViewModelProtocol

    var body: some View {
        List {
            Section {
                Text(viewModel.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(Theme.destructive)
                }
            }

            ForEach(viewModel.exercises) { exercise in
                Section(exercise.name) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        LoggedSetRow(
                            setNumber: viewModel.setNumberText(at: index),
                            detail: viewModel.setDetailText(for: set)
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
    }
}
