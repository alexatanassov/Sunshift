import SwiftUI

// MARK: - Colors

enum SunshiftColors {
    // Brand palette
    static let sunrisePeach  = Color(red: 1.00, green: 0.62, blue: 0.38)
    static let sunsetAmber   = Color(red: 0.97, green: 0.50, blue: 0.22)
    static let duskPurple    = Color(red: 0.56, green: 0.40, blue: 0.75)
    static let nightNavy     = Color(red: 0.08, green: 0.10, blue: 0.22)

    // Surfaces
    static let softBackground = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let cardBackground = Color(red: 1.00, green: 0.99, blue: 0.97)

    // Text
    static let primaryText   = Color(red: 0.12, green: 0.10, blue: 0.09)
    static let secondaryText = Color(red: 0.48, green: 0.43, blue: 0.38)
}

// MARK: - Typography

enum SunshiftTypography {
    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func title(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func headline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}

// MARK: - Spacing

enum SunshiftSpacing {
    static let xs:  CGFloat =  4
    static let sm:  CGFloat =  8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum SunshiftCornerRadius {
    static let small:  CGFloat =  8
    static let medium: CGFloat = 14
    static let large:  CGFloat = 22
    static let pill:   CGFloat = 100
}

// MARK: - Shadow

extension View {
    func cardShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Gradients

enum SunshiftGradients {
    static let sunrise = LinearGradient(
        colors: [SunshiftColors.sunrisePeach, SunshiftColors.sunsetAmber],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let dusk = LinearGradient(
        colors: [SunshiftColors.sunsetAmber, SunshiftColors.duskPurple],
        startPoint: .top,
        endPoint: .bottom
    )
    static let night = LinearGradient(
        colors: [SunshiftColors.duskPurple, SunshiftColors.nightNavy],
        startPoint: .top,
        endPoint: .bottom
    )
    static let softWarm = LinearGradient(
        colors: [
            SunshiftColors.softBackground,
            Color(red: 0.96, green: 0.93, blue: 0.89)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
