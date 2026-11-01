import Foundation
import PassKit

/// Passes have to be signed with a Pass Type ID certificate, which can't
/// happen on the device. The membership never changes, so the pass is signed
/// once on a Mac and shipped in the bundle.
final class BundleWalletPassRepository: WalletPassRepository {
    private static let membershipPassName = "Membership"

    var isWalletAvailable: Bool {
        PKPassLibrary.isPassLibraryAvailable()
    }

    func bundledMembershipPass() -> PKPass? {
        guard let url = Bundle.main.url(
            forResource: Self.membershipPassName,
            withExtension: "pkpass"
        ),
            let data = try? Data(contentsOf: url)
        else { return nil }

        return try? PKPass(data: data)
    }
}
