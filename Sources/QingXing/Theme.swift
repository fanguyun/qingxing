import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case sunrise
    case mint
    case sky
    case energy
    case violet
    case nature

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sunrise: "日出橙粉"
        case .mint: "薄荷健康"
        case .sky: "天空蓝紫"
        case .energy: "高能橙红"
        case .violet: "紫霞渐变"
        case .nature: "自然青绿"
        }
    }

    var accent: Color {
        switch self {
        case .sunrise: Color(hex: 0xF77099)
        case .mint: Color(hex: 0x34D399)
        case .sky: Color(hex: 0x38BDF8)
        case .energy: Color(hex: 0xF43F5E)
        case .violet: Color(hex: 0xA78BFA)
        case .nature: Color(hex: 0x22C55E)
        }
    }

    var accentSoft: Color {
        switch self {
        case .sunrise: Color(hex: 0xFFB76B)
        case .mint: Color(hex: 0x6EE7B7)
        case .sky: Color(hex: 0x818CF8)
        case .energy: Color(hex: 0xF97316)
        case .violet: Color(hex: 0xF472B6)
        case .nature: Color(hex: 0x2DD4BF)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [accentSoft, accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var warning: Color {
        Color(hex: 0xF59E42)
    }
}

private extension Color {
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
