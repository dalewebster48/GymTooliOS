import UIKit

final class ExerciseListViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!

    // MARK: - Properties

    private let viewModel: any ExerciseListViewModelProtocol

    // MARK: - Init

    init(viewModel: any ExerciseListViewModelProtocol) {
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
        configureNavigationItem()
        configureTableView()
        viewModel.viewDelegate = self
    }

    // MARK: - Configuration

    private func configureNavigationItem() {
        navigationItem.title = viewModel.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(didTapDone)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAdd)
        )
    }

    private func configureTableView() {
        tableView.register(
            UINib(nibName: "ExerciseCell", bundle: nil),
            forCellReuseIdentifier: ExerciseCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Actions

    @objc private func didTapDone() {
        viewModel.didTapDone()
    }

    @objc private func didTapAdd() {
        viewModel.didTapCreateExercise()
    }

    // MARK: - Theme

    private func applyTheme() {
        view.backgroundColor = Theme.background
        tableView.backgroundColor = Theme.background
        emptyStateLabel.textColor = Theme.secondaryText
    }
}

// MARK: - ExerciseListViewModelViewDelegate

extension ExerciseListViewController: ExerciseListViewModelViewDelegate {
    func bind(viewModel: any ExerciseListViewModelProtocol) {
        navigationItem.title = viewModel.title
        emptyStateLabel.text = viewModel.emptyStateMessage
        emptyStateLabel.isHidden = !viewModel.isEmpty
        tableView.isHidden = viewModel.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension ExerciseListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.exercises.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ExerciseCell.reuseIdentifier,
            for: indexPath
        )
        guard
            let exerciseCell = cell as? ExerciseCell,
            let exercise = viewModel.exercises[safe: indexPath.row]
        else {
            return cell
        }

        exerciseCell.configure(name: exercise.name, details: exercise.details)
        return exerciseCell
    }
}

// MARK: - UITableViewDelegate

extension ExerciseListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didSelectExercise(at: indexPath.row)
    }
}
