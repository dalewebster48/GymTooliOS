import SwiftUI
import UIKit

/// Every colour in the app. Views read from here rather than using literal
/// colours, so a palette change is a single-file edit.
enum Theme {
    // Brand colours. These two are hand-rolled per appearance; everything else
    // is a system semantic colour that already adapts.
    static var primaryAccent: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)
                : UIColor(red: 0.0, green: 0.4, blue: 0.9, alpha: 1)
        })
    }

    static var secondaryAccent: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.82, blue: 0.62, alpha: 1)
                : UIColor(red: 0.0, green: 0.62, blue: 0.42, alpha: 1)
        })
    }

    static var background: Color { Color(uiColor: .systemGroupedBackground) }
    static var cardBackground: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    static var fieldBackground: Color { Color(uiColor: .tertiarySystemFill) }
    static var separator: Color { Color(uiColor: .separator) }
    static var primaryText: Color { Color(uiColor: .label) }
    static var secondaryText: Color { Color(uiColor: .secondaryLabel) }
    static var placeholderText: Color { Color(uiColor: .placeholderText) }
    static var destructive: Color { Color(uiColor: .systemRed) }
}
