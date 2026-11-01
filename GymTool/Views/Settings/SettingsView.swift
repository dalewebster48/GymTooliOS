import SwiftUI

struct SettingsView: View {
    let viewModel: any SettingsViewModelProtocol

    var body: some View {
        List {
            Button {
                viewModel.didSelectMembership()
            } label: {
                Label(viewModel.membershipTitle, systemImage: viewModel.membershipSystemImage)
                    .foregroundStyle(Theme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.doneButtonTitle) { viewModel.didTapDone() }
            }
        }
    }
}
