import Foundation

extension Collection {
    /// Index access that returns `nil` rather than trapping when out of bounds.
    /// Table view callbacks can arrive against a stale index path while the
    /// view model is mid-reload, so reads driven by them go through this.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
