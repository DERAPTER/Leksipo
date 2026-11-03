//
//  SRSQualityButtonsView.swift
//  Leksipo
//
//  Created by Егор Халиков on 04.10.2026.
//

import SwiftUI

/// Панель из 6 кнопок оценки (0–5) для SRS-режима.
/// Раскладка: 3 «неправильных» в верхнем ряду, 3 «правильных» в нижнем.
/// Под каждой кнопкой — предсказание следующего интервала.
struct SRSQualityButtonsView: View {
    let intervalPreviews: [SRSQuality: Int]
    let onRate: (SRSQuality) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text("srs_how_well".localized())
                .font(.captionCustom)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 8) {
                ForEach(SRSQuality.wrongRow) { qualityButton($0) }
            }
            HStack(spacing: 8) {
                ForEach(SRSQuality.correctRow) { qualityButton($0) }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func qualityButton(_ quality: SRSQuality) -> some View {
        Button {
            onRate(quality)
        } label: {
            VStack(spacing: 2) {
                Text(quality.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(intervalLabel(for: quality))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(quality.color)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private func intervalLabel(for quality: SRSQuality) -> String {
        guard let days = intervalPreviews[quality] else { return "—" }
        if days == 1 { return "srs_interval_1d".localized() }
        return String(format: "srs_interval_nd".localized(), days)
    }
}
