import SwiftUI

enum SunshiftColor {
    static let sunrise    = Color(red: 1.0,  green: 0.55, blue: 0.2)
    static let sunset     = Color(red: 1.0,  green: 0.4,  blue: 0.5)
    static let sky        = Color(red: 0.2,  green: 0.6,  blue: 0.9)
    static let midnight   = Color(red: 0.07, green: 0.1,  blue: 0.2)
}

enum SunshiftFont {
    static func display(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
}
