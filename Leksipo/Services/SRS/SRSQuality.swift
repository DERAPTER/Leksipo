//
//  SRSQuality.swift
//  Leksipo
//
//  Created by Егор Халиков on 04.10.2026.
//

import SwiftUI

/// Оценка качества запоминания для SRS-режима.
/// Шкала 0–5 согласно классическому SM-2.
enum SRSQuality: Int, CaseIterable, Identifiable {
    case blackout   = 0  // полный провал
    case forgot     = 1  // забыл
    case almost     = 2  // почти вспомнил
    case hard       = 3  // вспомнил с трудом
    case remembered = 4  // вспомнил
    case easy       = 5  // легко
    
    var id: Int { rawValue }
    
    var titleKey: String {
        switch self {
        case .blackout:   return "srs_q0"
        case .forgot:     return "srs_q1"
        case .almost:     return "srs_q2"
        case .hard:       return "srs_q3"
        case .remembered: return "srs_q4"
        case .easy:       return "srs_q5"
        }
    }
    
    var title: String { titleKey.localized() }
    
    /// Ответ считается правильным, если оценка ≥ 3.
    var isCorrect: Bool { rawValue >= 3 }

    var requiresRelearning: Bool { rawValue < 4 }
    
    var color: Color {
        switch self {
        case .blackout:   return Color(red: 0.80, green: 0.25, blue: 0.25)  // тёмно-красный
        case .forgot:     return Color(red: 0.88, green: 0.38, blue: 0.25)  // красный
        case .almost:     return Color(red: 0.92, green: 0.55, blue: 0.25)  // оранжевый
        case .hard:       return Color(red: 0.90, green: 0.72, blue: 0.30)  // жёлтый
        case .remembered: return Color(red: 0.55, green: 0.75, blue: 0.40)  // светло-зелёный
        case .easy:       return Color(red: 0.30, green: 0.70, blue: 0.40)  // зелёный
        }
    }
    
    /// Раскладка для UI: 3 «неправильных» в верхнем ряду, 3 «правильных» в нижнем.
    static var wrongRow: [SRSQuality] { [.blackout, .forgot, .almost] }
    static var correctRow: [SRSQuality] { [.hard, .remembered, .easy] }
}
