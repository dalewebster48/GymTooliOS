import SwiftUI

struct MembershipView: View {
    let viewModel: any MembershipViewModelProtocol

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            Picker(
                viewModel.formatPickerTitle,
                selection: .action(viewModel.selectedFormat, viewModel.didSelectFormat)
            ) {
                ForEach(viewModel.formats) { format in
                    Text(viewModel.formatTitle(for: format))
                        .tag(format)
                }
            }
            .pickerStyle(.segmented)

            Spacer()
            barcode
                // The white margin is the barcode's quiet zone, not decoration —
                // scanners need clear space either side of the bars.
                .padding(24)
                .background(Theme.barcodeBackground, in: .rect(cornerRadius: 16))
            Spacer()
        }
        .padding()
        .background(Theme.background)
        .navigationTitle(viewModel.title)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: scenePhase) { _, phase in
            viewModel.didChangeAppActivity(isActive: phase == .active)
        }
    }

    @ViewBuilder
    private var barcode: some View {
        if let generated = viewModel.generatedBarcode {
            Image(generated, scale: 1, label: Text(viewModel.barcodeAccessibilityLabel))
                .resizable()
                .scaledToFit()
        } else if let asset = viewModel.barcodeAsset {
            Image(asset)
                .resizable()
                .scaledToFit()
                .accessibilityLabel(viewModel.barcodeAccessibilityLabel)
        }
    }
}
