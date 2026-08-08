import UIKit

final class WorkoutCell: UITableViewCell {

    static let reuseIdentifier = "WorkoutCell"

    // MARK: - Outlets

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        accessoryType = .disclosureIndicator
    }

    // MARK: - Configuration

    func configure(
        name: String,
        subtitle: String
    ) {
        nameLabel.text = name
        subtitleLabel.text = subtitle
    }

    // MARK: - Theme

    private func applyTheme() {
        backgroundColor = Theme.cardBackground
        nameLabel.textColor = Theme.primaryText
        subtitleLabel.textColor = Theme.secondaryText
    }
}
