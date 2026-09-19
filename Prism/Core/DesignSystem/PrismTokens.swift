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

enum PrismTypography {
    /// Editorial titles — New York system serif (Fraunces may be bundled later if licensed).
    static func display(_ size: CGFloat, weight: Font.Weight = .light) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .light, design: .serif)
    }

    static func headline() -> Font {
        .system(size: 17, weight: .semibold, design: .default)
    }

    static func body() -> Font {
        .system(size: 16, weight: .regular, design: .default)
    }

    static func caption() -> Font {
        .system(size: 12, weight: .medium, design: .default)
    }

    static func micro() -> Font {
        .system(size: 10, weight: .semibold, design: .default)
    }
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

enum PrismMaterials {
    static let glassOpacity: Double = 0.12
    static let scrimOpacity: Double = 0.55
}
