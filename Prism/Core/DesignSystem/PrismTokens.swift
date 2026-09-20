// Summary: Design tokens — colors, typography (Fraunces/Figtree/Encode Sans/Inter), spacing, motion from App Screens recreation.

import SwiftUI

enum PrismColors {
    /// Canvas behind flipped backdrop art.
    static let backgroundDeep = Color(red: 0.08, green: 0.07, blue: 0.09) // #141118-ish
    static let backgroundMid = Color(red: 0.10, green: 0.09, blue: 0.13) // #1a1620
    static let glassFill = Color(red: 28 / 255, green: 28 / 255, blue: 31 / 255).opacity(0.48)
    static let glassStroke = Color.white.opacity(0.30)
    static let glassStrokeSoft = Color.white.opacity(0.22)
    static let tabBarFill = Color(red: 20 / 255, green: 17 / 255, blue: 24 / 255).opacity(0.72)
    static let buttonDark = Color(red: 44 / 255, green: 44 / 255, blue: 44 / 255) // #2C2C2C
    static let buttonInk = Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255)

    static let violet = Color(red: 126 / 255, green: 87 / 255, blue: 194 / 255) // #7E57C2
    static let violetSoft = Color(red: 179 / 255, green: 157 / 255, blue: 219 / 255) // #B39DDB
    static let lavender = Color(red: 217 / 255, green: 204 / 255, blue: 245 / 255)
    static let statusGreen = Color(red: 64 / 255, green: 150 / 255, blue: 42 / 255) // #40962A
    static let statusGreenSoft = Color(red: 156 / 255, green: 217 / 255, blue: 140 / 255) // #9CD98C
    static let statusAmber = Color(red: 247 / 255, green: 148 / 255, blue: 32 / 255) // #F79420
    static let statusAmberSoft = Color(red: 247 / 255, green: 180 / 255, blue: 99 / 255) // #F7B463

    static let magenta = Color(red: 0.90, green: 0.25, blue: 0.65)
    static let cyan = Color(red: 0.35, green: 0.85, blue: 0.95)
    static let warmLight = Color(red: 0.98, green: 0.88, blue: 0.70)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textTertiary = Color.white.opacity(0.48)
    static let textOnLight = Color(red: 44 / 255, green: 44 / 255, blue: 44 / 255)
    static let danger = Color(red: 0.95, green: 0.35, blue: 0.40)
    static let successSoft = statusGreenSoft

    // Legacy tag aliases → tone system
    static let tagWant = violet
    static let tagNeed = Color(red: 0.30, green: 0.55, blue: 0.95)
    static let tagDream = Color(red: 0.90, green: 0.45, blue: 0.75)
    static let tagGift = Color(red: 0.25, green: 0.65, blue: 0.90)
    static let tagFashion = Color(red: 0.95, green: 0.30, blue: 0.55)
    static let tagPriority = statusAmber
}

/// Tag / chip tones from recreation HTML `TONE`.
enum PrismTone: String, CaseIterable {
    case intent, intentOutline, priority, topic, done, off

    var background: Color {
        switch self {
        case .intent: return PrismColors.violet
        case .intentOutline: return .clear
        case .priority: return PrismColors.statusAmber
        case .topic: return Color.white.opacity(0.10)
        case .done: return PrismColors.statusGreen
        case .off: return Color.black.opacity(0.45)
        }
    }

    var border: Color {
        switch self {
        case .intent: return PrismColors.violet
        case .intentOutline: return PrismColors.violetSoft
        case .priority: return PrismColors.statusAmber
        case .topic: return Color.white.opacity(0.50)
        case .done: return PrismColors.statusGreen
        case .off: return Color.white.opacity(0.28)
        }
    }

    var foreground: Color {
        switch self {
        case .intent, .done: return .white
        case .intentOutline: return PrismColors.lavender
        case .priority: return PrismColors.textOnLight
        case .topic: return .white
        case .off: return Color.white.opacity(0.90)
        }
    }
}

enum PrismGradients {
    /// Prefer recreation backdrop art over this wash for in-app chrome.
    static let atmospheric = LinearGradient(
        colors: [PrismColors.backgroundDeep, PrismColors.backgroundMid],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardFade = LinearGradient(
        colors: [Color.black.opacity(0), Color.black.opacity(0.85)],
        startPoint: .init(x: 0.5, y: 0.47),
        endPoint: .bottom
    )
}

enum PrismFonts {
    fileprivate struct Family {
        let postScriptName: String
    }

    fileprivate static let fraunces: Family? = register(dataAsset: "FrauncesVariable")
    fileprivate static let inter: Family? = register(dataAsset: "InterVariable")
    fileprivate static let figtree: Family? = register(dataAsset: "FigtreeVariable")
    fileprivate static let encodeSans: Family? = register(dataAsset: "EncodeSansVariable")

    private static func register(dataAsset name: String) -> Family? {
        guard let asset = NSDataAsset(name: name),
              let provider = CGDataProvider(data: asset.data as CFData),
              let cgFont = CGFont(provider),
              let psName = cgFont.postScriptName as String? else { return nil }
        var error: Unmanaged<CFError>?
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
    /// Display / titles — Fraunces Light.
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

    static func title(_ size: CGFloat = 32) -> Font {
        display(size, weight: .light)
    }

    /// Metrics / money — Figtree.
    static func number(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let family = PrismFonts.figtree {
            return PrismFonts.font(family, size: size, variations: [
                "wght": PrismFonts.wght(weight)
            ])
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    /// Tab / chrome labels — Encode Sans.
    static func chrome(_ size: CGFloat = 9.5, weight: Font.Weight = .regular) -> Font {
        if let family = PrismFonts.encodeSans {
            return PrismFonts.font(family, size: size, variations: [
                "wght": PrismFonts.wght(weight),
                "wdth": 100
            ])
        }
        return .system(size: size, weight: weight, design: .default)
    }

    /// Body — Inter.
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
    static let mono = Font.system(size: 10, weight: .regular, design: .monospaced)
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
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let pill: CGFloat = 999
}

enum PrismMotion {
    static let quick: Double = 0.18
    static let standard: Double = 0.28
    static let gentle: Double = 0.45
    static let archival: Double = 0.55
}

enum PrismHaptics {
    static func decision() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func save() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func soft() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

enum PrismBackdrop {
    static let blurRadius: CGFloat = 80
    static let imageBlurRadius: CGFloat = 14
    static let materialOpacity: Double = 0.22
    static let scrimOpacity: Double = 0.12
}

enum PrismMaterials {
    static let glassOpacity: Double = 0.12
    static let scrimOpacity: Double = 0.55
}
