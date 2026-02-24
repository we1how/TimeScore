//
//  Extensions.swift
//  TimeScore
//
//  颜色扩展和工具函数
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    /// 主绿色 - #1ded23
    static let primaryGreen = Color(hex: "#1ded23")

    /// 浅背景色 - #f6f8f6
    static let bgLight = Color(hex: "#f6f8f6")

    /// 深背景色 - #0a0f0a
    static let bgDark = Color(hex: "#0a0f0a")

    /// 恢复蓝色 - #3b82f6
    static let recoveryBlue = Color(hex: "#3b82f6")

    /// 亮绿色（高精力）- #00E600
    static let vibrantGreen = Color(hex: "#00E600")

    /// 金色（成就）- #FFD700
    static let accentGold = Color(hex: "#FFD700")

    /// 卡片背景色（浅色模式）- #F5F5F5
    static let cardBackground = Color(hex: "#F5F5F5")

    /// 边框颜色 - #E5E5E5
    static let borderColor = Color(hex: "#E5E5E5")

    /// 次要文字颜色 - #618963
    static let secondaryText = Color(hex: "#618963")

    /// 从 Hex 初始化颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    /// 隐藏滚动条
    func hideScrollIndicator() -> some View {
        if #available(iOS 16.0, *) {
            return self.scrollIndicators(.hidden)
        } else {
            return self
        }
    }

    /// 添加毛玻璃效果
    func glassmorphic(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// 添加标准卡片样式
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
    }
}

// MARK: - String Extensions

extension String {
    /// 等级显示名称
    var gradeDisplayName: String {
        switch self {
        case "S":  return NSLocalizedString("grade.s", comment: "Grade S")
        case "A":  return NSLocalizedString("grade.a", comment: "Grade A")
        case "B":  return NSLocalizedString("grade.b", comment: "Grade B")
        case "C":  return NSLocalizedString("grade.c", comment: "Grade C")
        case "D":  return NSLocalizedString("grade.d", comment: "Grade D")
        case "R1": return NSLocalizedString("grade.r1", comment: "Grade R1")
        case "R2": return NSLocalizedString("grade.r2", comment: "Grade R2")
        case "R3": return NSLocalizedString("grade.r3", comment: "Grade R3")
        default:   return self
        }
    }

    /// 等级颜色
    var gradeColor: Color {
        switch self {
        case "S":  return .vibrantGreen
        case "A":  return .primaryGreen
        case "B":  return Color(hex: "#4CAF50")
        case "C":  return Color(hex: "#FF9800")
        case "D":  return Color(hex: "#F44336")
        case "R1", "R2", "R3": return .recoveryBlue
        default:   return .gray
        }
    }
}

// MARK: - Date Extensions

extension Date {
    /// 格式化显示时间
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    /// 格式化显示日期
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: self)
    }

    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}

// MARK: - Double Extensions

extension Double {
    /// 格式化为积分显示（取整）
    var pointsDisplay: String {
        String(format: "%.0f", self)
    }

    /// 格式化为带符号的积分
    var signedPointsDisplay: String {
        if self >= 0 {
            return "+\(pointsDisplay)"
        } else {
            return pointsDisplay
        }
    }
}

// MARK: - Animation Constants

struct AnimationConstants {
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let easeOut = Animation.easeOut(duration: 0.2)
    static let easeInOut = Animation.easeInOut(duration: 0.3)
}

// MARK: - Layout Constants

struct LayoutConstants {
    static let screenPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 24
    static let iconSize: CGFloat = 24
    static let spacing: CGFloat = 16
}
