import SwiftUI

struct HistoryListView: View {
    let viewModel: any HistoryListViewModelProtocol

    var body: some View {
        List {
            if let session = viewModel.resumableSession {
                Section {
                    Button {
                        viewModel.didTapResumeSession()
                    } label: {
                        WorkoutRow(
                            name: session.workoutName,
                            subtitle: viewModel.resumeSubtitle
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text(viewModel.resumeSectionTitle)
                }
            }

            ForEach(viewModel.items) { item in
                Button {
                    viewModel.didSelectItem(id: item.entryId)
                } label: {
                    HistoryEntryRow(
                        name: item.workoutName,
                        date: viewModel.subtitle(for: item),
                        detail: viewModel.detailText(for: item)
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        viewModel.didRequestDeleteItem(id: item.entryId)
                    }
                }
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
