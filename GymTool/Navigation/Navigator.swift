import Foundation

@MainActor
protocol Navigator: AnyObject {
    func navigate(_ action: NavigationAction)
    func dismiss(completion: (() -> Void)?)
}

extension Navigator {
    func dismiss() {
        dismiss(completion: nil)
    }
}
