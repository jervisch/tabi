import SwiftUI

/// Design tokens — TABi design kit (`design/DESIGN.md` + ASSET_MANIFEST.json).
enum TABiColor {
    static let washiHex: UInt32 = 0xF6F0E4
    static let sumiHex: UInt32 = 0x34312C
    static let indigoHex: UInt32 = 0x557C91
    static let skyHex: UInt32 = 0x8FC5D8
    static let mossHex: UInt32 = 0x8FA477
    static let peachHex: UInt32 = 0xE9A59A
    static let vermilionHex: UInt32 = 0xC95B45
    static let sandHex: UInt32 = 0xDCC8A5

    /// `#F6F0E4` — primary background
    static var washi: Color { Color(hex: washiHex) }
    /// `#34312C` — primary text
    static var sumi: Color { Color(hex: sumiHex) }
    /// `#557C91` — map/water/primary cool accent
    static var indigo: Color { Color(hex: indigoHex) }
    /// `#8FC5D8` — sky/water surfaces
    static var sky: Color { Color(hex: skyHex) }
    /// `#8FA477` — land/vegetation
    static var moss: Color { Color(hex: mossHex) }
    /// `#E9A59A` — flowers/soft accents
    static var peach: Color { Color(hex: peachHex) }
    /// `#C95B45` — primary interactive accent
    static var vermilion: Color { Color(hex: vermilionHex) }
    /// `#DCC8A5` — secondary surfaces
    static var sand: Color { Color(hex: sandHex) }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
