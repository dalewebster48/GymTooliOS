import UIKit

final class ExerciseSelectionCell: UITableViewCell {

    static let reuseIdentifier = "ExerciseSelectionCell"

    // MARK: - Outlets

    @IBOutlet private weak var orderLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        orderLabel.layer.cornerRadius = 14
        orderLabel.layer.masksToBounds = true
    }

    // MARK: - Configuration

    func configure(
        name: String,
        details: String,
        selectionOrder: Int?
    ) {
        nameLabel.text = name
        detailsLabel.text = details
        detailsLabel.isHidden = details.isEmpty

        if let selectionOrder {
            orderLabel.text = String(selectionOrder)
            orderLabel.backgroundColor = Theme.primaryAccent
            orderLabel.textColor = .white
            accessoryType = .checkmark
        } else {
            orderLabel.text = nil
            orderLabel.backgroundColor = Theme.fieldBackground
            accessoryType = .none
        }
    }

    // MARK: - Theme

    private func applyTheme() {
        backgroundColor = Theme.cardBackground
        tintColor = Theme.primaryAccent
        nameLabel.textColor = Theme.primaryText
        detailsLabel.textColor = Theme.secondaryText
    }
}
