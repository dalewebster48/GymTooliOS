import Foundation
import Observation

@MainActor
protocol SettingsViewModelProtocol: AnyObject, Observable {
    var title: String { get }
    var doneButtonTitle: String { get }
    var membershipTitle: String { get }
    var membershipSystemImage: String { get }

    func didSelectMembership()
    func didTapDone()
}

@Observable
@MainActor
final class SettingsViewModel: SettingsViewModelProtocol {
    @ObservationIgnored private let navigator: any Navigator

    let title = "Settings"
    let doneButtonTitle = "Done"
    let membershipTitle = "Gym Membership"
    let membershipSystemImage = "barcode"

    init(navigator: any Navigator) {
        self.navigator = navigator
    }

    func didSelectMembership() {
        navigator.navigate(.push(.membership))
    }

    func didTapDone() {
        navigator.dismiss()
    }
}
