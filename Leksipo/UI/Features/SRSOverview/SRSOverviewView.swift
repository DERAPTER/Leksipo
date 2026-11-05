//
//  SRSOverviewView.swift
//  Leksipo
//
//  Created by Егор Халиков on 07.10.2026.
//

import SwiftUI

struct SRSOverviewView: View {
    @Environment(AppContainer.self) private var container
    @State private var viewModel: SRSOverviewViewModel
    @State private var isHelpExpanded = false
    
    init(container: AppContainer) {
        _viewModel = State(initialValue: SRSOverviewViewModel(
            cardRepository: container.cardRepository,
            statsRepository: container.statsRepository
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    statusCard
                    streakCard
                    infoCard
                }
                .padding()
                .padding(.bottom, 100)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("srs_section_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.load()
            }
            .task { viewModel.load() }
            .onAppear { viewModel.load() }
            .onChange(of: viewModel.hasSRSExperience, initial: true) { _, hasExperience in
                guard let hasExperience else { return }
                isHelpExpanded = !hasExperience
            }
        }
    }
    
    // MARK: - Streak
    
    private var streakCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(streakColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(streakColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("srs_streak_label".localized())
                    .font(.bodyCustom.weight(.semibold))
                    .foregroundColor(.textPrimary)
                Text(streakSubtitle)
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text("\(viewModel.srsStreak)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(streakColor)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 2)
    }
    
    private var streakColor: Color {
        viewModel.isSRSClearedToday ? .orange : .gray
    }
    
    private var streakSubtitle: String {
        if viewModel.srsStreak == 0 {
            return "srs_streak_empty".localized()
        }
        if !viewModel.isSRSClearedToday {
            return "srs_streak_keep_it_up".localized()
        }
        return "days_in_row".localized()
    }
    
    // MARK: - Status
    
    @ViewBuilder
    private var statusCard: some View {
        if let overview = viewModel.overview {
            if overview.dueToday > 0 {
                dueTodayCard(overview)
            } else {
                caughtUpCard(overview)
            }
        } else {
            Color.clear.frame(height: 1)
        }
    }
    
    private func dueTodayCard(_ overview: SRSOverview) -> some View {
        VStack(spacing: 16) {
            MascotView(pose: .sad)
                .frame(width: 144, height: 104)

            HStack(alignment: .firstTextBaseline) {
                Text("srs_overview_available_today".localized())
                    .font(.bodyCustom)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(overview.dueToday)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.accent)
            }
            
            if overview.overdueCount > 0 || overview.newCardsAvailable > 0 {
                HStack(spacing: 10) {
                    if overview.overdueCount > 0 {
                        pill(
                            text: String(format: "srs_overview_overdue_count".localized(),
                                         overview.overdueCount),
                            color: .wrong
                        )
                    }
                    if overview.newCardsAvailable > 0 {
                        pill(
                            text: String(format: "srs_overview_new_count".localized(),
                                         overview.newCardsAvailable),
                            color: .accent
                        )
                    }
                    Spacer()
                }
            }
            
            NavigationLink {
                SRSView(container: container)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.body)
                    Text("srs_overview_start".localized())
                        .font(.bodyCustom.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accent)
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
            
            if let nextDate = overview.nextReviewDate, overview.nextReviewCount > 0 {
                Divider().background(Color.stroke)
                
                HStack {
                    Text("srs_overview_next_review".localized())
                        .font(.captionCustom)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(viewModel.formattedNextDate(nextDate)) · \(overview.nextReviewCount)")
                        .font(.captionCustom.weight(.medium))
                        .foregroundColor(.textPrimary)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 2)
    }
    
    private func caughtUpCard(_ overview: SRSOverview) -> some View {
        VStack(spacing: 16) {
            MascotView(pose: .rest)
                .frame(width: 180, height: 130)
            
            Text("srs_overview_all_caught_up".localized())
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("srs_overview_all_caught_up_desc".localized())
                .font(.captionCustom)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            if let nextDate = overview.nextReviewDate, overview.nextReviewCount > 0 {
                Divider()
                    .background(Color.stroke)
                    .padding(.vertical, 4)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("srs_overview_next_review".localized())
                            .font(.captionCustom)
                            .foregroundColor(.textSecondary)
                        Text(viewModel.formattedNextDate(nextDate))
                            .font(.bodyCustom.weight(.semibold))
                            .foregroundColor(.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("srs_overview_cards".localized())
                            .font(.captionCustom)
                            .foregroundColor(.textSecondary)
                        Text("\(overview.nextReviewCount)")
                            .font(.bodyCustom.weight(.semibold))
                            .foregroundColor(.accent)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 2)
    }
    
    private func pill(text: String, color: Color) -> some View {
        Text(text)
            .font(.captionCustom)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.15)))
    }
    
    // MARK: - Info
    
    private var infoCard: some View {
        DisclosureGroup(isExpanded: $isHelpExpanded) {
            Text("srs_overview_how_it_works_desc".localized())
                .font(.captionCustom)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.accent)
                Text("srs_overview_how_it_works".localized())
                    .font(.bodyCustom.weight(.semibold))
                    .foregroundColor(.textPrimary)
            }
        }
        .tint(Color.accent)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .shadow(color: .shadowColor, radius: 8, x: 0, y: 2)
    }
}
