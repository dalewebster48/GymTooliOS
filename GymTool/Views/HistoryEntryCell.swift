import UIKit

final class HistoryEntryCell: UITableViewCell {

    static let reuseIdentifier = "HistoryEntryCell"

    // MARK: - Outlets

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        accessoryType = .disclosureIndicator
    }

    // MARK: - Configuration

    func configure(
        name: String,
        date: String,
        detail: String
    ) {
        nameLabel.text = name
        dateLabel.text = date
        detailLabel.text = detail
    }

    // MARK: - Theme

    private func applyTheme() {
        backgroundColor = Theme.cardBackground
        nameLabel.textColor = Theme.primaryText
        dateLabel.textColor = Theme.secondaryText
        detailLabel.textColor = Theme.secondaryText
    }
}
