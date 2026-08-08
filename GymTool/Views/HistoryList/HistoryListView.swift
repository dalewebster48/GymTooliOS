import SwiftUI

struct HistoryListView: View {
    let viewModel: any HistoryListViewModelProtocol

    var body: some View {
        List {
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                Button {
                    viewModel.didSelectItem(at: index)
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
                        viewModel.didRequestDeleteItem(at: index)
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
        .onAppear { viewModel.onAppear() }
    }
}
