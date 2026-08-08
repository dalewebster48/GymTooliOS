import Foundation

@MainActor
protocol Navigator: AnyObject {
    func navigate(_ action: NavigationAction)
    /// Unwinds one push on the active tab. Distinct from `dismiss`, which only
    /// closes a modal.
    func pop()
    func dismiss(completion: (() -> Void)?)
}

extension Navigator {
    func dismiss() {
        dismiss(completion: nil)
    }
}
