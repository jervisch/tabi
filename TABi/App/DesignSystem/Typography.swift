import SwiftUI

/// Bundled fonts: Noto Serif/Sans CJK JP (JP), EB Garamond (EN). See Fonts/FONT_SOURCES.md (OFL).
enum TABiFont {
    // PostScript names as registered via UIAppFonts
    private static let serifRegular = "NotoSerifCJKjp-Regular"
    private static let serifBold = "NotoSerifCJKjp-Bold"
    private static let sansRegular = "NotoSansCJKjp-Regular"
    private static let sansBold = "NotoSansCJKjp-Bold"
    private static let garamondRegular = "EBGaramond12-Regular"
    private static let garamondBold = "EBGaramond12-Bold"

    private static func isBold(_ weight: Font.Weight) -> Bool {
        switch weight {
        case .medium, .semibold, .bold, .heavy, .black: true
        default: false
        }
    }

    /// JP serif headline (Mincho-like).
    static func title(_ size: CGFloat = 30, weight: Font.Weight = .regular) -> Font {
        .custom(isBold(weight) ? serifBold : serifRegular, size: size)
    }

    /// Large brand 旅
    static func brand(_ size: CGFloat = 40) -> Font {
        .custom(serifRegular, size: size)
    }

    /// English editorial serif (EB Garamond).
    static func placeEnglish(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .custom(isBold(weight) ? garamondBold : garamondRegular, size: size)
    }

    /// Japanese place name (serif).
    static func placeJapanese(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        .custom(isBold(weight) ? serifBold : serifRegular, size: size)
    }

    static func body(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .custom(isBold(weight) ? sansBold : sansRegular, size: size)
    }

    static func caption(_ size: CGFloat = 12, weight: Font.Weight = .regular) -> Font {
        .custom(isBold(weight) ? sansBold : sansRegular, size: size)
    }

    static func monoDate(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    static func navLabel(_ size: CGFloat = 11, weight: Font.Weight = .regular) -> Font {
        .custom(isBold(weight) ? sansBold : sansRegular, size: size)
    }
}
