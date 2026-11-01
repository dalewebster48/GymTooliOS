import PassKit

protocol WalletPassRepository: AnyObject {
    /// False where there is no Wallet to add to, such as some iPads.
    var isWalletAvailable: Bool { get }

    /// The membership pass shipped in the app bundle, or nil if it isn't
    /// there or won't parse. See `Wallet/make-membership-pass.sh`.
    func bundledMembershipPass() -> PKPass?
}
