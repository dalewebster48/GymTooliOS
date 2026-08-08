import UIKit

/// A tab this container can page between. Each tab owns its own nav bar
/// buttons, so the container never needs to know what they do.
protocol HomeTabContent: UIViewController {
    func makeLeadingBarButtonItems() -> [UIBarButtonItem]
    func makeTrailingBarButtonItems() -> [UIBarButtonItem]
}

/// Root screen: a segmented control over a `UIPageViewController`, so the two
/// tabs can be swiped between as well as tapped. `UITabBarController` does not
/// support swiping, which is why this is a custom container.
final class HomeContainerViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: any HomeContainerViewModelProtocol
    private let pages: [any HomeTabContent]

    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: viewModel.tabs.map(\.title))
        control.selectedSegmentIndex = viewModel.selectedTab.rawValue
        control.addTarget(self, action: #selector(didChangeSegment), for: .valueChanged)
        return control
    }()

    private lazy var pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )

    // MARK: - Init

    init(
        viewModel: any HomeContainerViewModelProtocol,
        pages: [any HomeTabContent]
    ) {
        self.viewModel = viewModel
        self.pages = pages
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        navigationItem.titleView = segmentedControl
        addPageViewController()
        viewModel.viewDelegate = self
    }

    // MARK: - Configuration

    private func addPageViewController() {
        pageViewController.dataSource = self
        pageViewController.delegate = self

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        pageViewController.didMove(toParent: self)

        if let first = pages.first {
            pageViewController.setViewControllers([first], direction: .forward, animated: false)
        }
    }

    private func showPage(for tab: HomeTab, animated: Bool) {
        guard
            let target = pages[safe: tab.rawValue],
            let current = pageViewController.viewControllers?.first,
            current !== target,
            let currentIndex = pages.firstIndex(where: { $0 === current })
        else {
            return
        }

        let direction: UIPageViewController.NavigationDirection =
            tab.rawValue > currentIndex ? .forward : .reverse
        pageViewController.setViewControllers([target], direction: direction, animated: animated)
    }

    private func updateBarButtonItems(for tab: HomeTab) {
        guard let page = pages[safe: tab.rawValue] else { return }
        navigationItem.leftBarButtonItems = page.makeLeadingBarButtonItems()
        navigationItem.rightBarButtonItems = page.makeTrailingBarButtonItems()
    }

    // MARK: - Actions

    @objc private func didChangeSegment(_ sender: UISegmentedControl) {
        viewModel.didSelectTab(at: sender.selectedSegmentIndex)
    }

    // MARK: - Theme

    private func applyTheme() {
        view.backgroundColor = Theme.background
        segmentedControl.selectedSegmentTintColor = Theme.cardBackground
    }
}

// MARK: - HomeContainerViewModelViewDelegate

extension HomeContainerViewController: HomeContainerViewModelViewDelegate {
    func bind(viewModel: any HomeContainerViewModelProtocol) {
        let tab = viewModel.selectedTab
        if segmentedControl.selectedSegmentIndex != tab.rawValue {
            segmentedControl.selectedSegmentIndex = tab.rawValue
        }
        showPage(for: tab, animated: true)
        updateBarButtonItems(for: tab)
    }
}

// MARK: - UIPageViewControllerDataSource

extension HomeContainerViewController: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }) else { return nil }
        return pages[safe: index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }) else { return nil }
        return pages[safe: index + 1]
    }
}

// MARK: - UIPageViewControllerDelegate

extension HomeContainerViewController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard
            completed,
            let current = pageViewController.viewControllers?.first,
            let index = pages.firstIndex(where: { $0 === current })
        else {
            return
        }
        viewModel.didPageTo(index: index)
    }
}
