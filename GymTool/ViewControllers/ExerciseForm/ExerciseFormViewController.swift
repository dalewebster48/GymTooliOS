import UIKit

final class ExerciseFormViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var detailsLabel: UILabel!
    @IBOutlet private weak var detailsTextView: UITextView!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var deleteButton: UIButton!

    // MARK: - Properties

    private let viewModel: any ExerciseFormViewModelProtocol

    // MARK: - Init

    init(viewModel: any ExerciseFormViewModelProtocol) {
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
        detailsTextView.delegate = self
        detailsTextView.layer.cornerRadius = 8
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

    // MARK: - Actions

    @IBAction private func nameEditingChanged(_ sender: UITextField) {
        viewModel.didUpdateName(sender.text ?? "")
    }

    @objc private func didTapCancel() {
        viewModel.didTapCancel()
    }

    @objc private func didTapSave() {
        viewModel.didTapSave()
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

    // MARK: - Theme

    private func applyTheme() {
        view.backgroundColor = Theme.background
        nameLabel.textColor = Theme.secondaryText
        detailsLabel.textColor = Theme.secondaryText
        nameTextField.textColor = Theme.primaryText
        detailsTextView.textColor = Theme.primaryText
        detailsTextView.backgroundColor = Theme.fieldBackground
        errorLabel.textColor = Theme.destructive
        deleteButton.setTitleColor(Theme.destructive, for: .normal)
    }
}

// MARK: - ExerciseFormViewModelViewDelegate

extension ExerciseFormViewController: ExerciseFormViewModelViewDelegate {
    func bind(viewModel: any ExerciseFormViewModelProtocol) {
        navigationItem.title = viewModel.title
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.canSave
        errorLabel.text = viewModel.errorMessage
        errorLabel.isHidden = viewModel.errorMessage == nil
        deleteButton.setTitle(viewModel.deleteButtonTitle, for: .normal)
        deleteButton.isHidden = !viewModel.canDelete

        // Assign only on a genuine difference. In edit mode the first bind
        // populates the fields; while typing the values already match, so the
        // caret is never disturbed.
        if nameTextField.text != viewModel.name {
            nameTextField.text = viewModel.name
        }
        if detailsTextView.text != viewModel.details {
            detailsTextView.text = viewModel.details
        }
    }
}

// MARK: - UITextViewDelegate

extension ExerciseFormViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        viewModel.didUpdateDetails(textView.text ?? "")
    }
}
