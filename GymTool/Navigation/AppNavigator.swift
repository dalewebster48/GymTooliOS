import Foundation
import Observation
import SwiftUI

/// Navigation state, not navigation commands. `navigate`, `pop` and `dismiss`
/// only mutate this state; SwiftUI does the presenting.
@Observable
@MainActor
final class AppNavigator: Navigator {
    /// Which tab is in front. This is navigation state rather than view state,
    /// because a push has to know which stack it lands on.
    var selectedTab: AppTab = .workouts

    /// One push stack per tab, so switching tabs preserves where you were. A
    /// tab's root screen is not in its path — this is everything above it.
    var paths: [AppTab: [NavigationRoute]] = [:]

    /// The presented sheet. Only one level is ever needed: every modal is
    /// raised from a tab's stack, and none of them presents another.
    var modal: NavigationRoute?

    func navigate(_ action: NavigationAction) {
        switch action {
        case .push(let route):
            paths[selectedTab, default: []].append(route)

        case .modal(let route):
            modal = route
        }
    }

    func pop() {
        guard var path = paths[selectedTab], !path.isEmpty else { return }
        path.removeLast()
        paths[selectedTab] = path
    }

    func dismiss(completion: (() -> Void)?) {
        modal = nil
        completion?()
    }

    /// The stack binding for one tab's `NavigationStack`.
    func path(for tab: AppTab) -> Binding<[NavigationRoute]> {
        Binding(
            get: { self.paths[tab] ?? [] },
            set: { self.paths[tab] = $0 }
        )
    }
}
