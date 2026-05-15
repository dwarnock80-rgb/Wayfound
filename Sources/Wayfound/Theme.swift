import SwiftUI

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

enum WayfoundTheme {
    static let background = Color(hex: 0xF6F2EA)
    static let panel = Color(hex: 0xFFFDF8)
    static let ink = Color(hex: 0x26312D)
    static let secondaryInk = Color(hex: 0x66746D)
    static let sage = Color(hex: 0x8AA897)
    static let deepSage = Color(hex: 0x4F6F61)
    static let teal = Color(hex: 0x7CA7A5)
    static let warm = Color(hex: 0xD8B99A)
    static let rose = Color(hex: 0xC98780)
    static let line = Color(hex: 0xE7DDD1)
}

struct PremiumPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(WayfoundTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(WayfoundTheme.line, lineWidth: 1)
            )
            .shadow(color: WayfoundTheme.ink.opacity(0.06), radius: 18, y: 8)
    }
}

extension View {
    func premiumPanel() -> some View {
        modifier(PremiumPanel())
    }
}
