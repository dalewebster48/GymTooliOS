import UIKit

final class UIScreenBrightnessRepository: ScreenBrightnessRepository {
    var brightness: Double? {
        screen.map { Double($0.brightness) }
    }

    func setBrightness(_ brightness: Double) {
        screen?.brightness = CGFloat(brightness)
    }

    /// `UIScreen.main` is deprecated, so the screen is reached through the
    /// scene the app is showing in. GymTool only ever has the one.
    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen
    }
}
