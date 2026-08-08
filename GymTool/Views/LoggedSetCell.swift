import UIKit

final class LoggedSetCell: UITableViewCell {

    static let reuseIdentifier = "LoggedSetCell"

    // MARK: - Outlets

    @IBOutlet private weak var setNumberLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        selectionStyle = .none
    }

    // MARK: - Configuration

    func configure(
        setNumber: String,
        detail: String
    ) {
        setNumberLabel.text = setNumber
        detailLabel.text = detail
    }

    // MARK: - Theme

    private func applyTheme() {
        backgroundColor = Theme.cardBackground
        setNumberLabel.textColor = Theme.secondaryText
        detailLabel.textColor = Theme.primaryText
    }
}
