import SwiftUI

/// Design tokens — TABi palette (see AGENTS.md).
enum TABiColor {
    static let washiHex: UInt32 = 0xF5F1E8
    static let sumiHex: UInt32 = 0x252525
    static let mossHex: UInt32 = 0x68705A
    static let indigoHex: UInt32 = 0x26384A
    static let vermilionHex: UInt32 = 0xC95745

    /// `#F5F1E8` — paper background
    static var washi: Color { Color(hex: washiHex) }
    /// `#252525` — primary ink
    static var sumi: Color { Color(hex: sumiHex) }
    /// `#68705A` — visited / nature accent
    static var moss: Color { Color(hex: mossHex) }
    /// `#26384A` — map water / deep accent
    static var indigo: Color { Color(hex: indigoHex) }
    /// `#C95745` — sparing highlight
    static var vermilion: Color { Color(hex: vermilionHex) }
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
