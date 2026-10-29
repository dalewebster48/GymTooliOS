import CoreGraphics
import DeveloperToolsSupport
import Foundation
import Observation

enum MembershipBarcodeFormat: CaseIterable, Identifiable {
    /// The membership number re-encoded by the app, in a format Apple Wallet
    /// can display.
    case code128
    /// The gym's own Code 39 barcode, as a bundled image.
    case original

    var id: Self { self }
}

@MainActor
protocol MembershipViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var barcodeAccessibilityLabel: String { get }
    var formatPickerTitle: String { get }
    var formats: [MembershipBarcodeFormat] { get }
    var selectedFormat: MembershipBarcodeFormat { get }
    /// Set when the selected format is drawn by the app.
    var generatedBarcode: CGImage? { get }
    /// Set when the selected format is the bundled image.
    var barcodeAsset: ImageResource? { get }

    func onAppear()
    func onDisappear()
    func didChangeAppActivity(isActive: Bool)
    func formatTitle(for format: MembershipBarcodeFormat) -> String
    func didSelectFormat(_ format: MembershipBarcodeFormat)
}

/// Shows the gym membership barcode, with the screen at full brightness so the
/// front-desk scanner can read it.
///
/// The gym issues Code 39, which Apple Wallet can't display. Code 128 is on
/// trial: if the scanner accepts the same number in that format, it can go in
/// a Wallet pass. The original stays one tap away in case it doesn't.
@Observable
@MainActor
final class MembershipViewModel: MembershipViewModelProtocol {
    private static let membershipNumber = "8323249159"

    @ObservationIgnored private let screenBrightnessService: any ScreenBrightnessService

    // Both have to hold for the barcode to actually be in front of someone.
    // Disappearing covers switching tabs; activity covers leaving the app,
    // which never fires `onDisappear`.
    @ObservationIgnored private var isOnScreen = false
    @ObservationIgnored private var isAppActive = true

    private var code128Image: CGImage?

    let title = "Membership"
    let barcodeAccessibilityLabel = "Membership barcode"
    let formatPickerTitle = "Barcode format"
    let formats = MembershipBarcodeFormat.allCases
    var selectedFormat = MembershipBarcodeFormat.code128

    var generatedBarcode: CGImage? {
        selectedFormat == .code128 ? code128Image : nil
    }

    var barcodeAsset: ImageResource? {
        selectedFormat == .original ? .membershipBarcode : nil
    }

    init(screenBrightnessService: any ScreenBrightnessService) {
        self.screenBrightnessService = screenBrightnessService
    }

    func onAppear() {
        if code128Image == nil {
            code128Image = Code128Barcode.makeImage(message: Self.membershipNumber)
        }
        isOnScreen = true
        updateBrightness()
    }

    func onDisappear() {
        isOnScreen = false
        updateBrightness()
    }

    func didChangeAppActivity(isActive: Bool) {
        isAppActive = isActive
        updateBrightness()
    }

    func formatTitle(for format: MembershipBarcodeFormat) -> String {
        switch format {
        case .code128: "Code 128"
        case .original: "Original"
        }
    }

    func didSelectFormat(_ format: MembershipBarcodeFormat) {
        selectedFormat = format
    }

    private func updateBrightness() {
        if isOnScreen && isAppActive {
            screenBrightnessService.raise()
        } else {
            screenBrightnessService.restore()
        }
    }
}
