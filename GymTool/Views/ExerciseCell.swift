import UIKit

final class ExerciseCell: UITableViewCell {

    static let reuseIdentifier = "ExerciseCell"

    // MARK: - Outlets

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var detailsLabel: UILabel!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        accessoryType = .disclosureIndicator
    }

    // MARK: - Configuration

    func configure(
        name: String,
        details: String
    ) {
        nameLabel.text = name
        detailsLabel.text = details
        detailsLabel.isHidden = details.isEmpty
    }

    // MARK: - Theme

    private func applyTheme() {
        backgroundColor = Theme.cardBackground
        nameLabel.textColor = Theme.primaryText
        detailsLabel.textColor = Theme.secondaryText
    }
}
