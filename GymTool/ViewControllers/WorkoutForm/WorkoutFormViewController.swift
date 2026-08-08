import UIKit

final class WorkoutFormViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var exercisesLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var emptyStateLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var deleteButton: UIButton!

    // MARK: - Properties

    private let viewModel: any WorkoutFormViewModelProtocol

    // MARK: - Init

    init(viewModel: any WorkoutFormViewModelProtocol) {
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
        nameTextField.becomeFirstResponder()
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
            barButtonSystemItem: .save,
            target: self,
            action: #selector(didTapSave)
        )
    }

    private func configureTableView() {
        tableView.register(
            UINib(nibName: "ExerciseSelectionCell", bundle: nil),
            forCellReuseIdentifier: ExerciseSelectionCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Actions

    @IBAction private func nameEditingChanged(_ sender: UITextField) {
        viewModel.didUpdateName(sender.text ?? "")
    }

    @IBAction private func didTapDelete(_ sender: UIButton) {
        view.endEditing(true)

        let alert = UIAlertController(
            title: viewModel.deleteConfirmationTitle,
            message: viewModel.deleteConfirmationMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.didConfirmDelete()
        })
        present(alert, animated: true)
    }

    @objc private func didTapCancel() {
        viewModel.didTapCancel()
    }

    @objc private func didTapSave() {
        viewModel.didTapSave()
    }

    // MARK: - Theme

    private func applyTheme() {
        view.backgroundColor = Theme.background
        tableView.backgroundColor = Theme.background
        nameLabel.textColor = Theme.secondaryText
        exercisesLabel.textColor = Theme.secondaryText
        nameTextField.textColor = Theme.primaryText
        emptyStateLabel.textColor = Theme.secondaryText
        errorLabel.textColor = Theme.destructive
        deleteButton.setTitleColor(Theme.destructive, for: .normal)
    }
}

// MARK: - WorkoutFormViewModelViewDelegate

extension WorkoutFormViewController: WorkoutFormViewModelViewDelegate {
    func bind(viewModel: any WorkoutFormViewModelProtocol) {
        navigationItem.title = viewModel.title
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.canSave
        emptyStateLabel.text = viewModel.emptyStateMessage
        emptyStateLabel.isHidden = viewModel.hasExercises
        tableView.isHidden = !viewModel.hasExercises
        errorLabel.text = viewModel.errorMessage
        errorLabel.isHidden = viewModel.errorMessage == nil
        deleteButton.setTitle(viewModel.deleteButtonTitle, for: .normal)
        deleteButton.isHidden = !viewModel.canDelete

        // Assign only on a genuine difference, so editing an existing workout
        // populates the field without the caret jumping while you type.
        if nameTextField.text != viewModel.name {
            nameTextField.text = viewModel.name
        }
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension WorkoutFormViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.exercises.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ExerciseSelectionCell.reuseIdentifier,
            for: indexPath
        )
        guard
            let selectionCell = cell as? ExerciseSelectionCell,
            let exercise = viewModel.exercises[safe: indexPath.row]
        else {
            return cell
        }

        selectionCell.configure(
            name: exercise.name,
            details: exercise.details,
            selectionOrder: viewModel.selectionOrder(at: indexPath.row)
        )
        return selectionCell
    }
}

// MARK: - UITableViewDelegate

extension WorkoutFormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.didToggleExercise(at: indexPath.row)
    }
}
