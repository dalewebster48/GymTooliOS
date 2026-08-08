import UIKit

final class LogWorkoutViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var errorLabel: UILabel!

    // MARK: - Properties

    private let viewModel: any LogWorkoutViewModelProtocol

    /// The last set structure the table was built against. Reloading only when
    /// this changes stops keystrokes in a reps/weight field from rebuilding the
    /// table and dropping first responder.
    private var renderedSetsVersion = -1

    // MARK: - Init

    init(viewModel: any LogWorkoutViewModelProtocol) {
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
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Submit",
            style: .prominent,
            target: self,
            action: #selector(didTapSubmit)
        )
    }

    private func configureTableView() {
        tableView.register(
            UINib(nibName: "SetInputCell", bundle: nil),
            forCellReuseIdentifier: SetInputCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        configureSessionFooter()
    }

    /// Calories belong to the session, not to any exercise, so they live in the
    /// table footer rather than as an extra section — that keeps every
    /// section-indexed data source method free of special cases.
    private func configureSessionFooter() {
        let footer = SessionSummaryView()
        footer.delegate = self
        footer.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 88)
        tableView.tableFooterView = footer
    }

    // MARK: - Actions

    @objc private func didTapCancel() {
        viewModel.didTapCancel()
    }

    @objc private func didTapSubmit() {
        view.endEditing(true)
        viewModel.didTapSubmit()
    }

    @objc private func didTapAddSet(_ sender: UIButton) {
        view.endEditing(true)
        viewModel.didTapAddSet(inExerciseAt: sender.tag)
    }

    // MARK: - Theme

    private func applyTheme() {
        view.backgroundColor = Theme.background
        tableView.backgroundColor = Theme.background
        errorLabel.textColor = Theme.destructive
    }
}

// MARK: - LogWorkoutViewModelViewDelegate

extension LogWorkoutViewController: LogWorkoutViewModelViewDelegate {
    func bind(viewModel: any LogWorkoutViewModelProtocol) {
        navigationItem.title = viewModel.title
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.canSubmit
        errorLabel.text = viewModel.errorMessage
        errorLabel.isHidden = viewModel.errorMessage == nil

        guard renderedSetsVersion != viewModel.setsVersion else { return }
        renderedSetsVersion = viewModel.setsVersion
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension LogWorkoutViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.exerciseViewModels.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.exerciseViewModels[safe: section]?.sets.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.exerciseViewModels[safe: section]?.exerciseName
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SetInputCell.reuseIdentifier,
            for: indexPath
        )
        guard
            let setCell = cell as? SetInputCell,
            let exerciseViewModel = viewModel.exerciseViewModels[safe: indexPath.section]
        else {
            return cell
        }

        setCell.configure(
            setNumber: indexPath.row + 1,
            reps: exerciseViewModel.repsText(at: indexPath.row),
            weight: exerciseViewModel.weightText(at: indexPath.row),
            indexPath: indexPath
        )
        setCell.delegate = self
        return setCell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Keep at least one set per exercise so the section never renders empty.
        (viewModel.exerciseViewModels[safe: indexPath.section]?.sets.count ?? 0) > 1
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete else { return }
        viewModel.didDeleteSet(setIndex: indexPath.row, exerciseIndex: indexPath.section)
    }
}

// MARK: - UITableViewDelegate

extension LogWorkoutViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let container = UIView()
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Add Set"
        configuration.image = UIImage(systemName: "plus.circle.fill")
        configuration.imagePadding = 6
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 8, leading: 20, bottom: 8, trailing: 20
        )

        let button = UIButton(configuration: configuration)
        button.tag = section
        button.tintColor = Theme.primaryAccent
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(didTapAddSet(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }
}

// MARK: - SetInputCellDelegate

extension LogWorkoutViewController: SetInputCellDelegate {
    func setInputCell(_ cell: SetInputCell, didUpdateReps text: String, at indexPath: IndexPath) {
        viewModel.didUpdateReps(text, setIndex: indexPath.row, exerciseIndex: indexPath.section)
    }

    func setInputCell(_ cell: SetInputCell, didUpdateWeight text: String, at indexPath: IndexPath) {
        viewModel.didUpdateWeight(text, setIndex: indexPath.row, exerciseIndex: indexPath.section)
    }
}

// MARK: - SessionSummaryViewDelegate

extension LogWorkoutViewController: SessionSummaryViewDelegate {
    func sessionSummaryView(_ view: SessionSummaryView, didUpdateCalories text: String) {
        viewModel.didUpdateCalories(text)
    }
}
