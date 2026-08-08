import UIKit

protocol SessionSummaryViewDelegate: AnyObject {
    func sessionSummaryView(_ view: SessionSummaryView, didUpdateCalories text: String)
}

/// Footer for the logging table: the one value that belongs to the session as a
/// whole rather than to any single exercise.
final class SessionSummaryView: UIView {

    // MARK: - Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var caloriesTextField: UITextField!
    @IBOutlet private weak var unitLabel: UILabel!

    // MARK: - Properties

    weak var delegate: (any SessionSummaryViewDelegate)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
        guard let contentView = nib.instantiate(withOwner: self).first as? UIView else { return }
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        applyTheme()
        caloriesTextField.keyboardType = .numberPad
        caloriesTextField.layer.cornerRadius = 8
    }

    // MARK: - Actions

    @IBAction private func caloriesEditingChanged(_ sender: UITextField) {
        delegate?.sessionSummaryView(self, didUpdateCalories: sender.text ?? "")
    }

    // MARK: - Theme

    private func applyTheme() {
        backgroundColor = .clear
        titleLabel.textColor = Theme.secondaryText
        unitLabel.textColor = Theme.secondaryText
        caloriesTextField.textColor = Theme.primaryText
        caloriesTextField.backgroundColor = Theme.fieldBackground
    }
}
