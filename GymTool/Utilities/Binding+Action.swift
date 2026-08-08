import SwiftUI

extension Binding {
    /// Builds a binding whose writes go through a view model action method
    /// rather than straight into a stored property.
    ///
    /// `@Bindable` would be the shorter route, but it needs a concrete
    /// `Observable` type — views here hold `any …ViewModelProtocol` — and it
    /// writes to the property directly, bypassing any validation the view model
    /// does on the way in. Routing through an action keeps that funnel intact.
    static func action(
        get: @escaping () -> Value,
        set: @escaping (Value) -> Void
    ) -> Binding<Value> {
        Binding(get: get, set: set)
    }
}
