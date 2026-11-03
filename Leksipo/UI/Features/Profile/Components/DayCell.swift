//
//  DayCell.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct DayCell: View {
    let date: Date
    let isActive: Bool
    var goalCompleted = false
    var srsCleared = false
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = StudyDay.calendar
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(isToday ? Color.accent : Color.clear, lineWidth: 2)
                    )
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.bodyCustom)
                    .foregroundColor(textColor)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        if goalCompleted { return .accent }
        if srsCleared { return .orange }
        if isActive { return .accent.opacity(0.4) }
        if isToday { return .accent.opacity(0.2) }
        return .stroke.opacity(0.3)
    }
    
    private var textColor: Color {
        isActive ? .white : .textSecondary
    }
}
