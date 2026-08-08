import UIKit

final class HistoryListViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!

    // MARK: - Properties

    private let viewModel: any HistoryListViewModelProtocol

    // MARK: - Init

    init(viewModel: any HistoryListViewModelProtocol) {
        self.viewModel = viewModel
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
        configureTableView()
        viewModel.viewDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The tab can be swiped back to after a session was logged elsewhere,
        // and detail can pop back after a delete.
        viewModel.reload()
    }

    // MARK: - Configuration

    private func configureTableView() {
        tableView.register(
            UINib(nibName: "HistoryEntryCell", bundle: nil),
            forCellReuseIdentifier: HistoryEntryCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Theme

    private func applyTheme() {
        view.backgroundColor = Theme.background
        tableView.backgroundColor = Theme.background
        emptyStateLabel.textColor = Theme.secondaryText
    }
}

// MARK: - HomeTabContent

extension HistoryListViewController: HomeTabContent {
    func makeLeadingBarButtonItems() -> [UIBarButtonItem] { [] }
    func makeTrailingBarButtonItems() -> [UIBarButtonItem] { [] }
}

// MARK: - HistoryListViewModelViewDelegate

extension HistoryListViewController: HistoryListViewModelViewDelegate {
    func bind(viewModel: any HistoryListViewModelProtocol) {
        emptyStateLabel.text = viewModel.emptyStateMessage
        emptyStateLabel.isHidden = !viewModel.isEmpty
        tableView.isHidden = viewModel.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension HistoryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: HistoryEntryCell.reuseIdentifier,
            for: indexPath
        )
        guard
            let entryCell = cell as? HistoryEntryCell,
            let item = viewModel.items[safe: indexPath.row]
        else {
            return cell
        }

        entryCell.configure(
            name: item.workoutName,
            date: viewModel.subtitle(for: item),
            detail: viewModel.detailText(for: item)
        )
        return entryCell
    }
}

// MARK: - UITableViewDelegate

extension HistoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectItem(at: indexPath.row)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.confirmDelete(at: indexPath.row, completion: completion)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func confirmDelete(
        at index: Int,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: viewModel.deleteConfirmationTitle,
            message: viewModel.deleteConfirmationMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.didConfirmDeleteItem(at: index)
            completion(true)
        })
        present(alert, animated: true)
    }
}
