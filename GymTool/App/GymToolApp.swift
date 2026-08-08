import SwiftUI

@main
struct GymToolApp: App {
    /// The single root dependency container, built once for the app's lifetime.
    @State private var appContext = AppContext()

    var body: some Scene {
        WindowGroup {
            RootView(
                navigator: appContext.navigator,
                viewFactory: appContext.viewFactory
            )
        }
    }
}
