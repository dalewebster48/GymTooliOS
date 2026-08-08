import Foundation

enum HomeTab: Int, CaseIterable {
    case workouts
    case history

    var title: String {
        switch self {
        case .workouts: "Workouts"
        case .history: "History"
        }
    }
}

protocol HomeContainerViewModelProtocol: AnyObject {
    var tabs: [HomeTab] { get }
    var selectedTab: HomeTab { get }
    var viewDelegate: (any HomeContainerViewModelViewDelegate)? { get set }

    func didSelectTab(at index: Int)
    /// Called when the user swipes between pages, so the segmented control
    /// follows the page rather than the other way round.
    func didPageTo(index: Int)
}

protocol HomeContainerViewModelViewDelegate: AnyObject {
    func bind(viewModel: any HomeContainerViewModelProtocol)
}

final class HomeContainerViewModel: HomeContainerViewModelProtocol {
    weak var viewDelegate: (any HomeContainerViewModelViewDelegate)? {
        didSet { bind() }
    }

    let tabs = HomeTab.allCases

    var selectedTab: HomeTab = .workouts {
        didSet {
            guard selectedTab != oldValue else { return }
            bind()
        }
    }

    func didSelectTab(at index: Int) {
        guard let tab = HomeTab(rawValue: index) else { return }
        selectedTab = tab
    }

    func didPageTo(index: Int) {
        guard let tab = HomeTab(rawValue: index) else { return }
        selectedTab = tab
    }

    private func bind() {
        Task { @MainActor in
            viewDelegate?.bind(viewModel: self)
        }
    }
}
