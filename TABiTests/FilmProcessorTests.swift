import XCTest
import UIKit
@testable import TABi

final class FilmProcessorTests: XCTestCase {
    private let processor = TABiFilmProcessor()

    private func makeJPEG(color: UIColor, size: CGSize = CGSize(width: 64, height: 64)) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 1.0)!
    }

    func testProcessPreservesDimensionsAndProducesJPEG() throws {
        let input = makeJPEG(color: .systemTeal)
        let output = try processor.process(input)
        XCTAssertNotEqual(output, input)
        let inImage = UIImage(data: input)
        let outImage = UIImage(data: output)
        XCTAssertNotNil(outImage)
        XCTAssertEqual(inImage?.size, outImage?.size)
    }

    func testProcessHandlesFixtureLightingTypes() throws {
        let colors: [String: UIColor] = [
            "daylight": .white,
            "cloudy": .lightGray,
            "indoor": .brown,
            "night": .black,
            "neon": .systemPink,
            "portrait": .systemOrange,
            "greenery": .systemGreen
        ]
        for (name, color) in colors {
            let data = try processor.process(makeJPEG(color: color))
            XCTAssertFalse(data.isEmpty, name)
            XCTAssertNotNil(UIImage(data: data), name)
        }
    }

    func testLiftedBlacksIncreasesDarkestRegion() throws {
        let input = makeJPEG(color: .black)
        let output = try processor.process(input)
        let inMean = meanLuma(input)
        let outMean = meanLuma(output)
        XCTAssertGreaterThan(outMean, inMean, "Lifted blacks should raise dark image luminance")
    }

    private func meanLuma(_ data: Data) -> Double {
        guard let image = UIImage(data: data)?.cgImage else { return 0 }
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0 }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var total = 0.0
        let count = width * height
        for i in 0..<count {
            let r = Double(pixels[i * 4])
            let g = Double(pixels[i * 4 + 1])
            let b = Double(pixels[i * 4 + 2])
            total += (0.2126 * r + 0.7152 * g + 0.0722 * b)
        }
        return count > 0 ? total / Double(count) : 0
    }
}
