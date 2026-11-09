import SwiftUI

enum TABiFont {
    static func title(_ size: CGFloat = 30) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func placeEnglish(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func placeJapanese(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func monoDate(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}
