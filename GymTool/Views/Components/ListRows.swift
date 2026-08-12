import SwiftUI

/// The plain, value-in rows. None of these know about a view model — the screen
/// that owns them maps its view model onto these parameters.

struct WorkoutRow: View {
    let name: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
                .foregroundStyle(Theme.primaryText)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct ExerciseRow: View {
    let name: String
    let details: String
    /// Shows a trailing tick. Defaulted off, so rows that have no notion of
    /// being "done" don't have to say so.
    var isComplete: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Theme.primaryText)
                if !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.secondaryAccent)
                    // The subtitle already says how many sets were logged, so
                    // this is decoration rather than new information.
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct HistoryEntryRow: View {
    let name: String
    let date: String
    let detail: String
    /// Shown in red beneath the detail line. Defaulted nil so rows with nothing
    /// to flag don't have to say so.
    var warning: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
                .foregroundStyle(Theme.primaryText)
            Text(date)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            if let warning {
                Text(warning)
                    .font(.footnote)
                    .foregroundStyle(Theme.destructive)
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct LoggedSetRow: View {
    let setNumber: String
    let detail: String

    var body: some View {
        HStack {
            Text(setNumber)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            Text(detail)
                .font(.body)
                .foregroundStyle(Theme.primaryText)
        }
    }
}

/// A pickable exercise in the workout form. The badge shows the 1-based
/// position in the workout, which is also the order it will be performed in.
struct ExerciseSelectionRow: View {
    let name: String
    let details: String
    let selectionOrder: Int?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(selectionOrder == nil ? Theme.fieldBackground : Theme.primaryAccent)
                    .frame(width: 28, height: 28)
                if let selectionOrder {
                    Text("\(selectionOrder)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Theme.primaryText)
                if !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
