import XCTest
@testable import TABi

private struct RGBA: Equatable {
    let r: Int
    let g: Int
    let b: Int
    let a: Int
}

struct RGBATuple: Equatable {
    let r: Int, g: Int, b: Int, a: Int
}

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
        XCTAssertEqual(rgba(hex: TABiColor.washiHex), RGBA(r: 0xF6, g: 0xF0, b: 0xE4, a: 255), "Washi #F6F0E4")
        XCTAssertEqual(rgba(hex: TABiColor.sumiHex), RGBA(r: 0x34, g: 0x31, b: 0x2C, a: 255), "Sumi #34312C")
        XCTAssertEqual(rgba(hex: TABiColor.indigoHex), RGBA(r: 0x55, g: 0x7C, b: 0x91, a: 255), "Indigo #557C91")
        XCTAssertEqual(rgba(hex: TABiColor.skyHex), RGBA(r: 0x8F, g: 0xC5, b: 0xD8, a: 255), "Sky #8FC5D8")
        XCTAssertEqual(rgba(hex: TABiColor.mossHex), RGBA(r: 0x8F, g: 0xA4, b: 0x77, a: 255), "Moss #8FA477")
        XCTAssertEqual(rgba(hex: TABiColor.peachHex), RGBA(r: 0xE9, g: 0xA5, b: 0x9A, a: 255), "Peach #E9A59A")
        XCTAssertEqual(rgba(hex: TABiColor.vermilionHex), RGBA(r: 0xC9, g: 0x5B, b: 0x45, a: 255), "Vermilion #C95B45")
        XCTAssertEqual(rgba(hex: TABiColor.sandHex), RGBA(r: 0xDC, g: 0xC8, b: 0xA5, a: 255), "Sand #DCC8A5")
    }

    func testColorHexInitMatchesTokenComponents() {
        XCTAssertEqual(TABiColor.washi.rgba255, RGBATuple(r: 0xF6, g: 0xF0, b: 0xE4, a: 255))
        XCTAssertEqual(TABiColor.sumi.rgba255, RGBATuple(r: 0x34, g: 0x31, b: 0x2C, a: 255))
        XCTAssertEqual(TABiColor.moss.rgba255, RGBATuple(r: 0x8F, g: 0xA4, b: 0x77, a: 255))
        XCTAssertEqual(TABiColor.vermilion.rgba255, RGBATuple(r: 0xC9, g: 0x5B, b: 0x45, a: 255))
        XCTAssertEqual(TABiColor.indigo.rgba255, RGBATuple(r: 0x55, g: 0x7C, b: 0x91, a: 255))
        XCTAssertEqual(TABiColor.sky.rgba255, RGBATuple(r: 0x8F, g: 0xC5, b: 0xD8, a: 255))
        XCTAssertEqual(TABiColor.peach.rgba255, RGBATuple(r: 0xE9, g: 0xA5, b: 0x9A, a: 255))
        XCTAssertEqual(TABiColor.sand.rgba255, RGBATuple(r: 0xDC, g: 0xC8, b: 0xA5, a: 255))
    }

extension Color {
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
