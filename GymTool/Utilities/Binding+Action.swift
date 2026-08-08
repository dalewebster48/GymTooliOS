import SwiftUI

extension Binding {
    /// A binding that reads a view model property and writes through one of its
    /// action methods.
    ///
    ///     TextField("Name", text: .action(viewModel.name, viewModel.didUpdateName))
    ///
    /// `@Bindable` would be shorter, but it needs a concrete `Observable` type
    /// — views here hold `any …ViewModelProtocol` — and it writes straight to
    /// the stored property, bypassing any validation on the way in. Routing
    /// through an action keeps every mutation funnelled through one method.
    static func action(
        _ value: @escaping @autoclosure () -> Value,
        _ setter: @escaping (Value) -> Void
    ) -> Binding<Value> {
        Binding(get: value, set: setter)
    }
}

extension Binding where Value == Bool {
    /// A presentation flag the view model owns. Presenting is triggered by an
    /// action method, so only dismissal is reported back.
    static func presented(
        _ isPresented: @escaping @autoclosure () -> Bool,
        onDismiss: @escaping () -> Void
    ) -> Binding<Bool> {
        Binding(
            get: isPresented,
            set: { if !$0 { onDismiss() } }
        )
    }
}
