import UIKit

final class AppContext {
    let databaseProvider: any DatabaseProvider
    let dataAccess: any DataAccessContainer
    let services: ServicesContainer
    let viewModelFactory: ViewModelFactory
    let navigator: AppNavigator
    let viewControllerFactory: ViewControllerFactory

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
        let viewControllerFactory = ViewControllerFactory(viewModelFactory: viewModelFactory)

        navigator.configure(with: viewControllerFactory)

        self.databaseProvider = databaseProvider
        self.dataAccess = dataAccess
        self.services = services
        self.navigator = navigator
        self.viewModelFactory = viewModelFactory
        self.viewControllerFactory = viewControllerFactory
    }

    func bootstrap(window: UIWindow) {
        let rootViewController = viewControllerFactory.makeHomeContainerViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigator.setRootNavigationController(navigationController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
