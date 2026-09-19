// Summary: Design tokens — colors, gradients, typography, spacing, radii, motion, and haptics for Prism.

import SwiftUI

enum PrismColors {
    static let backgroundDeep = Color(red: 0.08, green: 0.02, blue: 0.16)
    static let backgroundMid = Color(red: 0.14, green: 0.04, blue: 0.28)
    static let violet = Color(red: 0.42, green: 0.10, blue: 0.72)
    static let magenta = Color(red: 0.90, green: 0.25, blue: 0.65)
    static let cyan = Color(red: 0.35, green: 0.85, blue: 0.95)
    static let lavender = Color(red: 0.75, green: 0.65, blue: 0.95)
    static let warmLight = Color(red: 0.98, green: 0.88, blue: 0.70)
    static let glassFill = Color.white.opacity(0.08)
    static let glassStroke = Color.white.opacity(0.22)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textTertiary = Color.white.opacity(0.48)
    static let danger = Color(red: 0.95, green: 0.35, blue: 0.40)
    static let successSoft = Color(red: 0.45, green: 0.85, blue: 0.70)

    static let tagWant = Color(red: 0.55, green: 0.35, blue: 0.95)
    static let tagNeed = Color(red: 0.30, green: 0.55, blue: 0.95)
    static let tagDream = Color(red: 0.90, green: 0.45, blue: 0.75)
    static let tagGift = Color(red: 0.25, green: 0.65, blue: 0.90)
    static let tagFashion = Color(red: 0.95, green: 0.30, blue: 0.55)
    static let tagPriority = Color(red: 0.98, green: 0.78, blue: 0.25)
}

enum PrismGradients {
    static let atmospheric = LinearGradient(
        colors: [
            PrismColors.backgroundDeep,
            PrismColors.violet.opacity(0.55),
            PrismColors.backgroundMid
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let prismShimmer = LinearGradient(
        colors: [
            PrismColors.magenta.opacity(0.35),
            PrismColors.cyan.opacity(0.25),
            PrismColors.lavender.opacity(0.30),
            PrismColors.warmLight.opacity(0.15)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassHighlight = LinearGradient(
        colors: [Color.white.opacity(0.18), Color.white.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Bundled brand fonts, loaded from the asset catalog (see scripts/fetch_fonts.sh).
/// If a font has not been installed yet, typography falls back to the system fonts.
enum PrismFonts {
    fileprivate struct Family {
        let postScriptName: String
    }

    fileprivate static let fraunces: Family? = register(dataAsset: "FrauncesVariable")
    fileprivate static let inter: Family? = register(dataAsset: "InterVariable")

    private static func register(dataAsset name: String) -> Family? {
        guard let asset = NSDataAsset(name: name),
              let provider = CGDataProvider(data: asset.data as CFData),
              let cgFont = CGFont(provider),
              let psName = cgFont.postScriptName as String? else { return nil }
        var error: Unmanaged<CFError>?
        // Ignore "already registered" errors; the font is usable either way.
        CTFontManagerRegisterGraphicsFont(cgFont, &error)
        return Family(postScriptName: psName)
    }

    private static func tag(_ s: String) -> NSNumber {
        NSNumber(value: s.utf8.reduce(0) { ($0 << 8) | UInt32($1) })
    }

    fileprivate static func font(_ family: Family, size: CGFloat, variations: [String: CGFloat]) -> Font {
        var axes: [NSNumber: NSNumber] = [:]
        for (key, value) in variations { axes[tag(key)] = NSNumber(value: Double(value)) }
        let variationKey = UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String)
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: family.postScriptName,
            variationKey: axes
        ])
        return Font(UIFont(descriptor: descriptor, size: size) as CTFont)
    }

    fileprivate static func wght(_ weight: Font.Weight) -> CGFloat {
        switch weight {
        case .ultraLight: return 200
        case .thin: return 250
        case .light: return 300
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        case .heavy: return 800
        case .black: return 900
        default: return 400
        }
    }
}

enum PrismTypography {
    /// Titles and wordmark — Fraunces Light (falls back to the system serif).
    static func display(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        if let family = PrismFonts.fraunces {
            return PrismFonts.font(family, size: size, variations: [
                "wght": PrismFonts.wght(weight),
                "opsz": min(max(size, 9), 144),
                "SOFT": 0,
                "WONK": 0
            ])
        }
        return .system(size: size, weight: weight, design: .serif)
    }

    static func title(_ size: CGFloat = 28) -> Font {
        display(size, weight: .light)
    }

    /// Body font — Inter (falls back to the system font).
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        if let family = PrismFonts.inter {
            return PrismFonts.font(family, size: size, variations: [
                "wght": PrismFonts.wght(weight),
                "opsz": min(max(size, 14), 32)
            ])
        }
        return .system(size: size, weight: weight, design: .default)
    }

    static func headline() -> Font { body(17, weight: .semibold) }
    static func caption() -> Font { body(12, weight: .medium) }
    static func micro() -> Font { body(10, weight: .semibold) }
}

enum PrismSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum PrismRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let pill: CGFloat = 999
}

enum PrismMotion {
    static let quick: Double = 0.18
    static let standard: Double = 0.28
    static let gentle: Double = 0.45
    static let archival: Double = 0.55
}

enum PrismHaptics {
    static func decision() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func save() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

enum PrismBackdrop {
    /// Uniform Gaussian blur applied to the app-wide background so text stays readable.
    static let blurRadius: CGFloat = 80
    /// Slight darkening on top of the blurred art (0 to disable).
    static let scrimOpacity: Double = 0.18
}

enum PrismMaterials {
    static let glassOpacity: Double = 0.12
    static let scrimOpacity: Double = 0.55
}
