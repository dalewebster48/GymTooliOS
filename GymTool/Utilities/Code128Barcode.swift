import CoreImage
import CoreImage.CIFilterBuiltins

enum Code128Barcode {
    /// Core Image draws one pixel per bar module. Enlarging that on screen
    /// either blurs it or, with nearest-neighbour, rounds some bars wider than
    /// others — and bar widths are what a scanner measures. So it is enlarged
    /// here by a whole number, and the screen only ever scales it down.
    private static let scale: CGFloat = 10

    /// Nil if `message` has characters Code 128 can't encode.
    static func makeImage(message: String) -> CGImage? {
        guard let data = message.data(using: .ascii) else { return nil }

        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = data
        // Taller than the default 32, for roughly the proportions of the gym's
        // own barcode. The default quiet space is kept: it is the clear margin
        // scanners need either side of the bars.
        filter.barcodeHeight = 50

        guard let output = filter.outputImage else { return nil }
        let enlarged = output
            .samplingNearest()
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return CIContext().createCGImage(enlarged, from: enlarged.extent)
    }
}
