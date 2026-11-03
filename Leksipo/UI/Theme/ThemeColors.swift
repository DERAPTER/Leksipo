//
//  ThemeColors.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct ThemeColors {
    let background: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let stroke: Color
    let shadowColor: Color
    let correct: Color
    let wrong: Color
    
    static func forTheme(_ theme: AppTheme) -> ThemeColors {
        switch theme {
        case .beige:
            return ThemeColors(
                background: Color(red: 0.96, green: 0.93, blue: 0.88),
                cardBackground: Color(red: 0.94, green: 0.91, blue: 0.86),
                textPrimary: Color(red: 0.25, green: 0.2, blue: 0.15),
                textSecondary: Color(red: 0.5, green: 0.45, blue: 0.4),
                accent: Color(red: 0.8, green: 0.65, blue: 0.45),
                stroke: Color(red: 0.8, green: 0.76, blue: 0.7),
                shadowColor: Color.black.opacity(0.1),
                correct: .green,
                wrong: .red
            )
            
        case .green:
            return ThemeColors(
                background: Color(hex: "#051F20"),
                cardBackground: Color(hex: "#0B2B26"),
                textPrimary: Color(hex: "#8EB69B"),
                textSecondary: Color(hex: "#8EB69B").opacity(0.7),
                accent: Color(hex: "#235347"),
                stroke: Color(hex: "#163832"),
                shadowColor: Color.black.opacity(0.25),
                correct: Color(hex: "#8EB69B"),
                wrong: Color(hex: "#235347")
            )
            
        case .blue:
            return ThemeColors(
                background: Color(hex: "#021024"),
                cardBackground: Color(hex: "#052659"),
                textPrimary: Color(hex: "#C1E8FF"),
                textSecondary: Color(hex: "#7DA0CA"),
                accent: Color(hex: "#548383"),
                stroke: Color(hex: "#7DA0CA").opacity(0.5),
                shadowColor: Color.black.opacity(0.25),
                correct: .green,
                wrong: Color(hex: "#FEA38E")
            )
            
        case .pink:
            return ThemeColors(
                background: Color(hex: "#F6E5D0"),
                cardBackground: Color(hex: "#FFDFC3"),
                textPrimary: Color(hex: "#5D3A2A"),
                textSecondary: Color(hex: "#8B6B5A"),
                accent: Color(hex: "#FBA2AB"),
                stroke: Color(hex: "#F3B5A0"),
                shadowColor: Color(hex: "#FEA38E").opacity(0.3),
                correct: .green,
                wrong: Color(hex: "#FEA38E")
            )
        }
    }
}

// MARK: - Color from HEX

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
