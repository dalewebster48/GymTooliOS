import PassKit
import SwiftUI

struct MembershipView: View {
    let viewModel: any MembershipViewModelProtocol

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            if let barcode = viewModel.barcode {
                Image(barcode, scale: 1, label: Text(viewModel.barcodeAccessibilityLabel))
                    .resizable()
                    .scaledToFit()
                    // The white margin is the barcode's quiet zone, not
                    // decoration — scanners need clear space either side of
                    // the bars.
                    .padding(24)
                    .background(Theme.barcodeBackground, in: .rect(cornerRadius: 16))
            }
            Spacer()
            if let pass = viewModel.walletPass {
                // Presents Wallet's own add sheet, which also says when the
                // pass is already there.
                AddPassToWalletButton([pass]) { _ in }
                    .frame(height: 50)
            }
        }
        .padding()
        .background(Theme.background)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: scenePhase) { _, phase in
            viewModel.didChangeAppActivity(isActive: phase == .active)
        }
    }
}
