//
//  ActivityCalendarView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct ActivityCalendarView: View {
    let activityHistory: [DailyStat]
    let isDateActive: (Date) -> Bool
    
    @State private var currentMonth: Date = Date()
    @State private var selectedDate: Date?
    
    private let calendar = StudyDay.calendar
    
    private var daysOfWeek: [String] {
        ["calendar_mon", "calendar_tue", "calendar_wed", "calendar_thu",
         "calendar_fri", "calendar_sat", "calendar_sun"].map { $0.localized() }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            monthHeader
            
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.captionCustom)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            daysGrid
            
            legend
        }
        .padding(.vertical)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .shadowColor, radius: 5, x: 0, y: 2)
        .sheet(item: $selectedDate) { date in
            DayDetailSheet(date: date, stat: stat(for: date))
        }
    }
    
    // MARK: - Subviews
    
    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.accent)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(monthYearString)
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Button { shiftMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
    
    private var daysGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(0..<days.count, id: \.self) { index in
                if let date = days[index] {
                    DayCell(
                        date: date,
                        isActive: isDateActive(date),
                        goalCompleted: stat(for: date)?.goalCompleted ?? false,
                        srsCleared: stat(for: date)?.srsCleared ?? false,
                        isToday: calendar.isDateInToday(date),
                        onTap: { selectedDate = date }
                    )
                } else {
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var legend: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
            legendItem(color: .accent, text: "calendar_goal_completed".localized())
            legendItem(color: .orange, text: "calendar_srs_completed".localized())
            legendItem(color: .accent.opacity(0.4), text: "calendar_partial_progress".localized())
            legendItem(color: .stroke.opacity(0.3), text: "inactive_day".localized())
            legendItem(color: .accent.opacity(0.3), text: "today".localized(), stroke: .accent)
        }
        .padding(.top, 8)
        .padding(.horizontal)
    }
    
    private func legendItem(color: Color, text: String, stroke: Color? = nil) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(stroke ?? .clear, lineWidth: 1)
                )
            Text(text)
                .font(.caption2)
                .foregroundColor(.textSecondary)
        }
    }
    
    // MARK: - Logic
    
    private func stat(for date: Date) -> DailyStat? {
        activityHistory.first { $0.dateKey == DailyStat.makeKey(for: date) }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLanguage.locale
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    private func shiftMonth(by value: Int) {
        withAnimation {
            if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
                currentMonth = newDate
            }
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let firstDay = calendar.date(
            from: calendar.dateComponents([.year, .month], from: currentMonth)
        ) else { return [] }
        
        guard let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offset = firstWeekday == 1 ? 6 : firstWeekday - 2
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
}
