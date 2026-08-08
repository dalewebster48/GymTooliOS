import UIKit

final class AppNavigator: NSObject, Navigator {
    private var navigationController: UINavigationController?
    private weak var presentedNavigationController: UINavigationController?
    private var viewControllerFactory: ViewControllerFactory?

    func configure(with factory: ViewControllerFactory) {
        self.viewControllerFactory = factory
    }

    func setRootNavigationController(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.presentedNavigationController = navigationController
    }

    func navigate(_ action: NavigationAction) {
        guard let presentedNavigationController else { return }

        switch action {
        case .modal(let route):
            let viewController = makeViewController(for: route)
            let navController = UINavigationController(rootViewController: viewController)
            navController.modalPresentationStyle = .formSheet
            navController.presentationController?.delegate = self
            presentedNavigationController.present(navController, animated: true)
            self.presentedNavigationController = navController

        case .push(let route):
            let viewController = makeViewController(for: route)
            presentedNavigationController.pushViewController(viewController, animated: true)

        case .bottomSheet(let route):
            let viewController = makeViewController(for: route)
            viewController.modalPresentationStyle = .pageSheet
            if let sheet = viewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
            viewController.presentationController?.delegate = self
            presentedNavigationController.present(viewController, animated: true)
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        guard let presentedNavigationController else {
            completion?()
            return
        }

        let presenting = presentedNavigationController.presentingViewController as? UINavigationController

        presentedNavigationController.dismiss(animated: true) { [weak self] in
            self?.presentedNavigationController = presenting ?? self?.navigationController
            completion?()
        }
    }

    private func makeViewController(for route: NavigationRoute) -> UIViewController {
        guard let viewControllerFactory else {
            fatalError("ViewControllerFactory not configured on AppNavigator")
        }

        switch route {
        case .exerciseList:
            return viewControllerFactory.makeExerciseListViewController()

        case .exerciseForm(let mode, let onSave):
            return viewControllerFactory.makeExerciseFormViewController(mode: mode, onSave: onSave)

        case .workoutForm(let mode, let onSave):
            return viewControllerFactory.makeWorkoutFormViewController(mode: mode, onSave: onSave)

        case .logWorkout(let workoutId):
            return viewControllerFactory.makeLogWorkoutViewController(workoutId: workoutId)

        case .historyDetail(let entryId):
            return viewControllerFactory.makeHistoryDetailViewController(entryId: entryId)
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension AppNavigator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        let presenting = presentationController.presentingViewController as? UINavigationController
        presentedNavigationController = presenting ?? navigationController
    }
}