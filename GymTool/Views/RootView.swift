import SwiftUI

/// Owns the one `NavigationStack` and the sheet chain. Everything the navigator
/// records as state gets presented here and nowhere else.
struct RootView: View {
    @Bindable var navigator: AppNavigator
    let viewFactory: ViewFactory
    /// Passed in rather than built here — see `AppContext.homeContainerViewModel`.
    let homeContainerViewModel: any HomeContainerViewModelProtocol

    var body: some View {
        NavigationStack(path: $navigator.path) {
            viewFactory.makeHomeContainerView(viewModel: homeContainerViewModel)
                .navigationDestination(for: NavigationRoute.self) { route in
                    routedView(for: route)
                }
        }
        .sheet(isPresented: isPresented(level: 0)) {
            sheetContent(level: 0)
                // Level 1 is attached to level 0's content, because the app
                // presents a sheet from a sheet (Workouts → Exercises →
                // Exercise form). Two levels is the depth the app uses; a
                // recursive presenter would not type-check.
                .sheet(isPresented: isPresented(level: 1)) {
                    sheetContent(level: 1)
                }
        }
    }

    @ViewBuilder
    private func sheetContent(level: Int) -> some View {
        if let route = navigator.modalStack[safe: level] {
            NavigationStack {
                routedView(for: route)
            }
        }
    }

    /// `.id(route)` ties the screen's SwiftUI identity to the route it came
    /// from. Without it, replacing the route at a given position would reuse
    /// the previous screen's `@State` — and so its view model.
    private func routedView(for route: NavigationRoute) -> some View {
        viewFactory.view(for: route)
            .id(route)
    }

    /// Dismissing a sheet by swipe unwinds the stack to that level, which is
    /// what `AppNavigator.dismiss()` does programmatically.
    private func isPresented(level: Int) -> Binding<Bool> {
        Binding(
            get: { navigator.modalStack.count > level },
            set: { isPresented in
                guard !isPresented, navigator.modalStack.count > level else { return }
                navigator.modalStack.removeSubrange(level...)
            }
        )
    }
}
