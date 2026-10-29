import Foundation

protocol ScreenBrightnessRepository: AnyObject {
    /// From 0 (dimmest) to 1 (brightest), or nil when there is no screen to
    /// read yet — before the app's scene has connected.
    var brightness: Double? { get }

    func setBrightness(_ brightness: Double)
}
