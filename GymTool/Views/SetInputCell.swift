import UIKit

protocol SetInputCellDelegate: AnyObject {
    func setInputCell(_ cell: SetInputCell, didUpdateReps text: String, at indexPath: IndexPath)
    func setInputCell(_ cell: SetInputCell, didUpdateWeight text: String, at indexPath: IndexPath)
}

final class SetInputCell: UITableViewCell {

    static let reuseIdentifier = "SetInputCell"

    // MARK: - Outlets

    @IBOutlet private weak var setNumberLabel: UILabel!
    @IBOutlet private weak var repsTextField: UITextField!
    @IBOutlet private weak var repsCaptionLabel: UILabel!
    @IBOutlet private weak var weightTextField: UITextField!
    @IBOutlet private weak var weightCaptionLabel: UILabel!

    // MARK: - Properties

    weak var delegate: (any SetInputCellDelegate)?

    /// The position this cell was configured for, reported back with edits so
    /// the view model knows which set changed.
    private var indexPath: IndexPath?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        selectionStyle = .none
        repsTextField.keyboardType = .numberPad
        weightTextField.keyboardType = .decimalPad
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        delegate = nil
        indexPath = nil
    }

    // MARK: - Configuration

    func configure(
        setNumber: Int,
        reps: String,
        weight: String,
        indexPath: IndexPath
    ) {
        self.indexPath = indexPath
        setNumberLabel.text = "Set \(setNumber)"
        repsTextField.text = reps
        weightTextField.text = weight
    }

    // MARK: - Actions

    @IBAction private func repsEditingChanged(_ sender: UITextField) {
        guard let indexPath else { return }
        delegate?.setInputCell(self, didUpdateReps: sender.text ?? "", at: indexPath)
    }

    @IBAction private func weightEditingChanged(_ sender: UITextField) {
        guard let indexPath else { return }
        delegate?.setInputCell(self, didUpdateWeight: sender.text ?? "", at: indexPath)
    }

    // MARK: - Theme

    private func applyTheme() {
        backgroundColor = Theme.cardBackground
        setNumberLabel.textColor = Theme.secondaryText
        repsCaptionLabel.textColor = Theme.secondaryText
        weightCaptionLabel.textColor = Theme.secondaryText
        repsTextField.textColor = Theme.primaryText
        weightTextField.textColor = Theme.primaryText
        repsTextField.backgroundColor = Theme.fieldBackground
        weightTextField.backgroundColor = Theme.fieldBackground
        repsTextField.layer.cornerRadius = 8
        weightTextField.layer.cornerRadius = 8
    }
}
