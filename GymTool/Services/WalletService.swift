import PassKit

/// Apple Wallet passes the app can offer to add.
protocol WalletService: AnyObject {
    /// The gym membership pass, or nil when it can't be offered: no Wallet on
    /// this device, or no signed pass in the bundle.
    func membershipPass() -> PKPass?
}

final class WalletServiceImpl: WalletService {
    private let walletPassRepository: any WalletPassRepository

    init(walletPassRepository: any WalletPassRepository) {
        self.walletPassRepository = walletPassRepository
    }

    func membershipPass() -> PKPass? {
        guard walletPassRepository.isWalletAvailable else { return nil }
        return walletPassRepository.bundledMembershipPass()
    }
}
