import CoreGraphics
import Foundation
import Observation
import PassKit

@MainActor
protocol MembershipViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var barcodeAccessibilityLabel: String { get }
    var barcode: CGImage? { get }
    /// Nil hides the Add to Apple Wallet button.
    var walletPass: PKPass? { get }

    func onAppear()
    func onDisappear()
    func didChangeAppActivity(isActive: Bool)
}

/// Shows the gym membership barcode, with the screen at full brightness so the
/// front-desk scanner can read it, and offers the same barcode as a Wallet pass.
///
/// The gym issues Code 39, which Apple Wallet can't display. The front desk
/// accepts the same number as Code 128, so that is what's drawn here and what
/// the pass carries.
@Observable
@MainActor
final class MembershipViewModel: MembershipViewModelProtocol {
    /// Also in `Wallet/Membership.pass/pass.json` — change both together.
    private static let membershipNumber = "8323249159"

    @ObservationIgnored private let screenBrightnessService: any ScreenBrightnessService
    @ObservationIgnored private let walletService: any WalletService

    // Both have to hold for the barcode to actually be in front of someone.
    // Disappearing covers leaving the screen; activity covers leaving the app,
    // which never fires `onDisappear`.
    @ObservationIgnored private var isOnScreen = false
    @ObservationIgnored private var isAppActive = true

    let title = "Membership"
    let barcodeAccessibilityLabel = "Membership barcode"
    private(set) var barcode: CGImage?
    private(set) var walletPass: PKPass?

    init(
        screenBrightnessService: any ScreenBrightnessService,
        walletService: any WalletService
    ) {
        self.screenBrightnessService = screenBrightnessService
        self.walletService = walletService
    }

    func onAppear() {
        if barcode == nil {
            barcode = Code128Barcode.makeImage(message: Self.membershipNumber)
        }
        if walletPass == nil {
            walletPass = walletService.membershipPass()
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

    private func updateBrightness() {
        if isOnScreen && isAppActive {
            screenBrightnessService.raise()
        } else {
            screenBrightnessService.restore()
        }
    }
}
