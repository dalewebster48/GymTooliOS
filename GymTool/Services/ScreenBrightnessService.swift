import Foundation

/// Takes the display to full brightness for something that has to be scanned,
/// and puts it back afterwards.
protocol ScreenBrightnessService: AnyObject {
    /// Remembers the current brightness and goes to full. Does nothing while
    /// already raised, so the remembered level is never overwritten with the
    /// raised one.
    func raise()
    /// Returns to the brightness from before `raise()`. Does nothing when not
    /// raised.
    func restore()
}

final class ScreenBrightnessServiceImpl: ScreenBrightnessService {
    private let screenBrightnessRepository: any ScreenBrightnessRepository

    /// The level to go back to. Set only while raised.
    private var restoreLevel: Double?

    init(screenBrightnessRepository: any ScreenBrightnessRepository) {
        self.screenBrightnessRepository = screenBrightnessRepository
    }

    func raise() {
        guard restoreLevel == nil,
              let current = screenBrightnessRepository.brightness
        else { return }

        restoreLevel = current
        screenBrightnessRepository.setBrightness(1)
    }

    func restore() {
        guard let restoreLevel else { return }

        screenBrightnessRepository.setBrightness(restoreLevel)
        self.restoreLevel = nil
    }
}
