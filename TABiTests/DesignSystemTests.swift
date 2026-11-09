import XCTest
@testable import TABi

private struct RGBA: Equatable {
    let r: Int
    let g: Int
    let b: Int
    let a: Int
}

final class DesignSystemTests: XCTestCase {
    private func rgba(hex: UInt32) -> RGBA {
        RGBA(
            r: Int((hex >> 16) & 0xFF),
            g: Int((hex >> 8) & 0xFF),
            b: Int(hex & 0xFF),
            a: 255
        )
    }

    func testDesignTokenHexValues() {
        XCTAssertEqual(rgba(hex: TABiColor.washiHex), RGBA(r: 245, g: 241, b: 232, a: 255), "Washi #F5F1E8")
        XCTAssertEqual(rgba(hex: TABiColor.sumiHex), RGBA(r: 37, g: 37, b: 37, a: 255), "Sumi #252525")
        XCTAssertEqual(rgba(hex: TABiColor.mossHex), RGBA(r: 104, g: 112, b: 90, a: 255), "Moss #68705A")
        XCTAssertEqual(rgba(hex: TABiColor.indigoHex), RGBA(r: 38, g: 56, b: 74, a: 255), "Indigo #26384A")
        XCTAssertEqual(rgba(hex: TABiColor.vermilionHex), RGBA(r: 201, g: 87, b: 69, a: 255), "Vermilion #C95745")
    }

    func testColorHexInitMatchesTokenComponents() {
        XCTAssertEqual(TABiColor.washi.rgba255, RGBATuple(r: 245, g: 241, b: 232, a: 255))
        XCTAssertEqual(TABiColor.sumi.rgba255, RGBATuple(r: 37, g: 37, b: 37, a: 255))
        XCTAssertEqual(TABiColor.moss.rgba255, RGBATuple(r: 104, g: 112, b: 90, a: 255))
        XCTAssertEqual(TABiColor.indigo.rgba255, RGBATuple(r: 38, g: 56, b: 74, a: 255))
        XCTAssertEqual(TABiColor.vermilion.rgba255, RGBATuple(r: 201, g: 87, b: 69, a: 255))
    }
}

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RGBATuple: Equatable {
    let r: Int, g: Int, b: Int, a: Int
}

extension Color {
    /// Resolved sRGB components as 0–255, compared via `rgbTuple`.
    var rgba255: RGBATuple {
        #if canImport(UIKit)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGBATuple(
            r: Int((r * 255).rounded()),
            g: Int((g * 255).rounded()),
            b: Int((b * 255).rounded()),
            a: Int((a * 255).rounded())
        )
        #else
        return RGBATuple(r: 0, g: 0, b: 0, a: 0)
        #endif
    }
}
