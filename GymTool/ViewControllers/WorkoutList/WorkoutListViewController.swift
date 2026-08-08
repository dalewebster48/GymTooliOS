import UIKit

final class WorkoutListViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!

    // MARK: - Properties

    private let viewModel: any WorkoutListViewModelProtocol

    // MARK: - Init

    init(viewModel: any WorkoutListViewModelProtocol) {
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
            UINib(nibName: "WorkoutCell", bundle: nil),
            forCellReuseIdentifier: WorkoutCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Actions

    @objc private func didTapManage() {
        viewModel.didTapManageExercises()
    }

    @objc private func didTapAdd() {
        viewModel.didTapCreateWorkout()
    }

    // MARK: - Theme

    private func applyTheme() {
        view.backgroundColor = Theme.background
        tableView.backgroundColor = Theme.background
        emptyStateLabel.textColor = Theme.secondaryText
    }
}

// MARK: - WorkoutListViewModelViewDelegate

extension WorkoutListViewController: HomeTabContent {
    // The container owns the nav bar, so this tab supplies its own buttons.
    func makeLeadingBarButtonItems() -> [UIBarButtonItem] {
        [UIBarButtonItem(title: "Manage", style: .plain, target: self, action: #selector(didTapManage))]
    }

    func makeTrailingBarButtonItems() -> [UIBarButtonItem] {
        [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))]
    }
}

// MARK: - WorkoutListViewModelViewDelegate

extension WorkoutListViewController: WorkoutListViewModelViewDelegate {
    func bind(viewModel: any WorkoutListViewModelProtocol) {
        emptyStateLabel.text = viewModel.emptyStateMessage
        emptyStateLabel.isHidden = !viewModel.isEmpty
        tableView.isHidden = viewModel.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension WorkoutListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.workouts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: WorkoutCell.reuseIdentifier,
            for: indexPath
        )
        guard
            let workoutCell = cell as? WorkoutCell,
            let workout = viewModel.workouts[safe: indexPath.row]
        else {
            return cell
        }

        workoutCell.configure(
            name: workout.name,
            subtitle: viewModel.subtitle(for: workout)
        )
        return workoutCell
    }
}

// MARK: - UITableViewDelegate

extension WorkoutListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectWorkout(at: indexPath.row)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // Tapping a row starts logging, so editing lives behind a swipe.
        // Deleting now lives inside the edit screen.
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.viewModel.didSelectEditWorkout(at: indexPath.row)
            completion(true)
        }
        edit.backgroundColor = Theme.primaryAccent
        return UISwipeActionsConfiguration(actions: [edit])
    }
}
