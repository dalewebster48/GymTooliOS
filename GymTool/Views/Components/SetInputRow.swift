import SwiftUI

/// One editable set. Takes bindings rather than a view model so it stays a
/// reusable leaf — the screen builds those bindings from view model actions.
struct SetInputRow: View {
    let setNumber: Int
    @Binding var reps: String
    @Binding var weight: String

    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(setNumber)")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 56, alignment: .leading)

            numberField(placeholder: "0", text: $reps, keyboard: .numberPad)
            Text("reps")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)

            numberField(placeholder: "0", text: $weight, keyboard: .decimalPad)
            Text("kg")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.vertical, 2)
    }

    private func numberField(
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType
    ) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .multilineTextAlignment(.center)
            .frame(width: 64)
            .padding(.vertical, 6)
            .background(Theme.fieldBackground, in: RoundedRectangle(cornerRadius: 8))
    }
}

/// The calories field that sits under the logged sets.
struct SessionSummaryView: View {
    @Binding var calories: String

    var body: some View {
        HStack(spacing: 12) {
            Text("CALORIES BURNT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)

            Spacer()

            TextField("0", text: $calories)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 72)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Theme.fieldBackground, in: RoundedRectangle(cornerRadius: 8))

            Text("kcal")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}
