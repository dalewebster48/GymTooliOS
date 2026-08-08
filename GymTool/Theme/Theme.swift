import UIKit

enum Theme {
    static var primaryAccent: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
                : UIColor(red: 0.0, green: 0.4, blue: 0.9, alpha: 1.0)
        }
    }

    static var secondaryAccent: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.35, green: 0.82, blue: 0.62, alpha: 1.0)
                : UIColor(red: 0.0, green: 0.62, blue: 0.42, alpha: 1.0)
        }
    }

    static var background: UIColor {
        .systemGroupedBackground
    }

    static var cardBackground: UIColor {
        .secondarySystemGroupedBackground
    }

    static var fieldBackground: UIColor {
        .tertiarySystemFill
    }

    static var separator: UIColor {
        .separator
    }

    static var primaryText: UIColor {
        .label
    }

    static var secondaryText: UIColor {
        .secondaryLabel
    }

    static var placeholderText: UIColor {
        .placeholderText
    }

    static var destructive: UIColor {
        .systemRed
    }
}
