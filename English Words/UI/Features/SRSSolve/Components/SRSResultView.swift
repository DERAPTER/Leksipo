//
//  SRSResultView.swift
//  English Words
//
//  Created by Егор Халиков on 04.10.2026.
//

import SwiftUI

struct SRSResultView: View {
    let reviewedCount: Int
    let qualityCounts: [SRSQuality: Int]
    let nextReviewDate: Date?
    let nextReviewCount: Int
    let onFinish: () -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                header
                
                if reviewedCount > 0 {
                    breakdownSection
                }
                
                if let nextDate = nextReviewDate, nextReviewCount > 0 {
                    nextReviewSection(date: nextDate)
                }
                
                Spacer(minLength: 40)
                
                finishButton
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(spacing: 16) {
            MascotView(pose: .success)
                .frame(width: 180, height: 150)
            
            Text("srs_result_title".localized())
                .font(.largeTitleCustom)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(String(format: "srs_result_message".localized(), reviewedCount))
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 10)
    }
    
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("srs_result_breakdown".localized())
                .font(.bodyCustom.weight(.semibold))
                .foregroundColor(.textPrimary)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SRSQuality.allCases, id: \.self) { quality in
                    let count = qualityCounts[quality] ?? 0
                    if count > 0 {
                        qualityRow(quality: quality, count: count)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 2)
    }
    
    private func qualityRow(quality: SRSQuality, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(quality.color)
                .frame(width: 10, height: 10)
            
            Text(quality.title)
                .font(.captionCustom)
                .foregroundColor(.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Text("\(count)")
                .font(.captionCustom.weight(.bold))
                .foregroundColor(.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.appBackground.opacity(0.5))
        .cornerRadius(10)
    }
    
    private func nextReviewSection(date: Date) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundColor(.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("srs_overview_next_review".localized())
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
                
                Text(formattedDate(date))
                    .font(.bodyCustom.weight(.semibold))
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("srs_overview_cards".localized())
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
                
                Text("\(nextReviewCount)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.accent)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 2)
    }
    
    private var finishButton: some View {
        Button(action: onFinish) {
            Text("close".localized())
                .font(.bodyCustom.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accent)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 30)
    }
    
    // MARK: - Helpers
    
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLanguage.locale
        
        if calendar.isDateInTomorrow(date) {
            return "srs_overview_tomorrow".localized()
        }
        
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: .now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        
        if days <= 6 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date).capitalized
        }
        
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }
}
