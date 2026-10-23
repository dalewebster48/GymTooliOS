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

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var historyFormatted: String {
        Date.historyFormatter.string(from: self)
    }

    /// Time of day only, for sets within a session you already have the date of.
    var timeFormatted: String {
        Date.timeFormatter.string(from: self)
    }
}

extension Int {
    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    /// "1st", "2nd", … for performed order.
    var ordinalFormatted: String {
        Int.ordinalFormatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}
