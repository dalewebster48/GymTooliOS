import SwiftUI

struct HistoryDetailView: View {
    /// Held in `@State` so the instance survives re-renders. SwiftUI re-invokes
    /// the sheet / navigationDestination closure that built this view, and a
    /// fresh view model on each pass would wipe whatever the screen had.
    @State private var viewModel: any HistoryDetailViewModelProtocol

    init(viewModel: any HistoryDetailViewModelProtocol) {
        _viewModel = State(initialValue: viewModel)
    }

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

            Section(viewModel.healthSectionTitle) {
                if let caloriesText = viewModel.caloriesText {
                    metricRow("Calories", caloriesText)
                }
                if let heartRateText = viewModel.averageHeartRateText {
                    metricRow("Avg. Heart Rate", heartRateText)
                }
                if let durationText = viewModel.durationText {
                    metricRow("Duration", durationText)
                }

                if let healthMessage = viewModel.healthMessage {
                    Text(healthMessage)
                        .font(.footnote)
                        .foregroundStyle(Theme.destructive)
                }

                Button {
                    viewModel.didTapSync()
                } label: {
                    HStack {
                        Text(viewModel.syncButtonTitle)
                        if viewModel.isSyncing {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.primaryAccent)
                .disabled(!viewModel.canSync)
            }

            ForEach(viewModel.exercises) { exercise in
                Section(exercise.name) {
                    ForEach(exercise.sets) { set in
                        LoggedSetRow(
                            setNumber: viewModel.setNumberText(forSetId: set.id),
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

    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            Text(value)
                .foregroundStyle(Theme.primaryText)
        }
        .font(.subheadline)
    }
}
