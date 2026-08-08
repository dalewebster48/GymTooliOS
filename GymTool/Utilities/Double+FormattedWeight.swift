import Foundation

extension Double {
    /// Drops the decimal point for whole numbers so "60" doesn't read "60.0".
    var formattedWeight: String {
        self == rounded() ? String(Int(self)) : String(self)
    }
}
