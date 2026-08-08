import Foundation

@MainActor
final class AppContext {
    let databaseProvider: any DatabaseProvider
    let dataAccess: any DataAccessContainer
    let services: ServicesContainer
    let viewModelFactory: ViewModelFactory
    let navigator: AppNavigator
    let viewFactory: ViewFactory

    /// The root screen's view model, built once here rather than inside a view
    /// body. A view body runs on every render, so a view model created there
    /// would be replaced — along with its loaded data — on the next pass.
    let homeContainerViewModel: any HomeContainerViewModelProtocol

    init() {
        let databaseProvider: any DatabaseProvider
        do {
            let provider = try AppDatabaseProvider()
            try provider.migrate()
            databaseProvider = provider
        } catch {
            // The app has no meaningful behaviour without its store, and a
            // failed migration is not something the user can recover from.
            fatalError("Failed to open or migrate the database: \(error)")
        }

        let dataAccess = AppDataAccessContainer(databaseProvider: databaseProvider)
        let services = ServicesContainer(dataAccess: dataAccess)
        let navigator = AppNavigator()
        let viewModelFactory = ViewModelFactory(services: services, navigator: navigator)
        let viewFactory = ViewFactory(viewModelFactory: viewModelFactory)

        self.databaseProvider = databaseProvider
        self.dataAccess = dataAccess
        self.services = services
        self.navigator = navigator
        self.viewModelFactory = viewModelFactory
        self.viewFactory = viewFactory
        self.homeContainerViewModel = viewModelFactory.makeHomeContainerViewModel()
    }
}
