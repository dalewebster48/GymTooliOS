import Foundation

extension Date {
    /// Shared formatter — `DateFormatter` is expensive to build, so cells must
    /// never construct one per row.
    private static let historyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var historyFormatted: String {
        Date.historyFormatter.string(from: self)
    }
}
