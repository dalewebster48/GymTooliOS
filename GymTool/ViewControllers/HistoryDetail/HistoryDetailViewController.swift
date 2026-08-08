import UIKit

final class HistoryDetailViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var errorLabel: UILabel!

    // MARK: - Properties

    private let viewModel: any HistoryDetailViewModelProtocol

    // MARK: - Init

    init(viewModel: any HistoryDetailViewModelProtocol) {
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

    // MARK: - Configuration

    private func configureTableView() {
        tableView.register(
            UINib(nibName: "LoggedSetCell", bundle: nil),
            forCellReuseIdentifier: LoggedSetCell.reuseIdentifier
        )
        tableView.dataSource = self
    }

    // MARK: - Theme

    private func applyTheme() {
        view.backgroundColor = Theme.background
        tableView.backgroundColor = Theme.background
        summaryLabel.textColor = Theme.secondaryText
        errorLabel.textColor = Theme.destructive
    }
}

// MARK: - HistoryDetailViewModelViewDelegate

extension HistoryDetailViewController: HistoryDetailViewModelViewDelegate {
    func bind(viewModel: any HistoryDetailViewModelProtocol) {
        navigationItem.title = viewModel.title
        summaryLabel.text = viewModel.summaryText
        errorLabel.text = viewModel.errorMessage
        errorLabel.isHidden = viewModel.errorMessage == nil
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension HistoryDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.exercises.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.exercises[safe: section]?.sets.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.exercises[safe: section]?.name
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: LoggedSetCell.reuseIdentifier,
            for: indexPath
        )
        guard
            let setCell = cell as? LoggedSetCell,
            let set = viewModel.exercises[safe: indexPath.section]?.sets[safe: indexPath.row]
        else {
            return cell
        }

        setCell.configure(
            setNumber: viewModel.setNumberText(at: indexPath.row),
            detail: viewModel.setDetailText(for: set)
        )
        return setCell
    }
}
