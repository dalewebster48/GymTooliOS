import Foundation
import Observation

/// Navigation state, not navigation commands. `navigate` and `dismiss` only
/// mutate these two collections; SwiftUI does the presenting.
@Observable
@MainActor
final class AppNavigator: Navigator {
    /// How many stacked sheets `RootView` is wired to present.
    static let maximumModalDepth = 2

    /// The push stack, bound to the root `NavigationStack`. The root screen is
    /// not in here — this is everything on top of it.
    var path: [NavigationRoute] = []

    /// Presented sheets, outermost first. This is an array rather than a single
    /// optional because the app presents a sheet from a sheet (Workouts →
    /// Exercises → Exercise form). `RootView` presents a fixed two-level chain,
    /// which is the depth the app actually uses.
    var modalStack: [NavigationRoute] = []

    func navigate(_ action: NavigationAction) {
        switch action {
        case .push(let route):
            path.append(route)

        case .modal(let route):
            // `RootView` presents a fixed two-level chain, so a third stacked
            // sheet would be recorded here and never shown. Fail loudly rather
            // than silently doing nothing.
            assert(
                modalStack.count < Self.maximumModalDepth,
                "RootView presents at most \(Self.maximumModalDepth) stacked sheets"
            )
            modalStack.append(route)
        }
    }

    func dismiss(completion: (() -> Void)?) {
        if !modalStack.isEmpty {
            modalStack.removeLast()
        }
        completion?()
    }
}
