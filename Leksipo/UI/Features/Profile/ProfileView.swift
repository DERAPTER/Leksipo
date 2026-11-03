//
//  ProfileView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppContainer.self) private var container
    @AppStorage("userName") private var userName: String = ""
    @State private var viewModel: ProfileViewModel
    
    init(container: AppContainer) {
        _viewModel = State(initialValue: ProfileViewModel(
            statsRepository: container.statsRepository,
            cardRepository: container.cardRepository,
            groupRepository: container.groupRepository,
            achievementsService: container.achievementsService
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    avatarSection
                    
                    DailyProgressCard(
                        stats: viewModel.stats,
                        onTap: { viewModel.openGoalEditor() }
                    )
                    .padding(.horizontal)
                    
                    divider
                    
                    calendarSection
                    
                    divider
                    
                    statisticsSection
                    
                    divider
                    
                    achievementsSection
                }
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("profile_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(container: container)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(.accent)
                    }
                }
            }
            .refreshable { viewModel.load() }
            .task { viewModel.load() }
            .onAppear { viewModel.load() }
            .sheet(isPresented: $viewModel.showingGoalEditor) {
                GoalEditorSheet(
                    currentGoal: viewModel.stats.dailyGoal,
                    onSave: { viewModel.saveGoal($0) }
                )
            }
            .sheet(isPresented: $viewModel.showAllAchievements) {
                AllAchievementsSheet(achievements: viewModel.achievements)
            }
        }
    }
    
    // MARK: - Sections
    
    private var avatarSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accent)
            Text(userName.isEmpty ? "learner".localized() : userName)
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
        }
    }
    
    private var divider: some View {
        Divider()
            .background(Color.stroke)
            .padding(.horizontal)
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            expandableHeader(
                title: "activity_calendar".localized(),
                isExpanded: $viewModel.isCalendarExpanded
            )
            
            if viewModel.isCalendarExpanded {
                ActivityCalendarView(
                    activityHistory: viewModel.activityHistory,
                    isDateActive: viewModel.isDateActive
                )
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            expandableHeader(
                title: "statistics".localized(),
                isExpanded: $viewModel.isStatisticsExpanded
            )
            
            if viewModel.isStatisticsExpanded {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 16
                ) {
                    StatCard(title: "total_cards".localized(),
                             value: "\(viewModel.stats.totalCards)")
                    StatCard(title: "groups_count".localized(),
                             value: "\(viewModel.stats.userGroupsCount)")
                    StatCard(title: "favorites".localized(),
                             value: "\(viewModel.stats.favouritesCount)")
                    StatCard(title: "total_solved".localized(),
                             value: "\(viewModel.stats.totalSolved)")
                    StatCard(title: "achievements_unlocked".localized(),
                             value: "\(viewModel.unlockedAchievements.count)/\(viewModel.achievements.count)")
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            expandableHeader(
                title: "achievements".localized(),
                isExpanded: $viewModel.isAchievementsExpanded
            )
            
            if viewModel.isAchievementsExpanded {
                if viewModel.achievementsPreview.isEmpty {
                    Text("no_achievements_yet".localized())
                        .font(.bodyCustom)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.achievementsPreview) { status in
                                AchievementBadge(
                                    icon: status.achievement.icon,
                                    title: status.achievement.title,
                                    unlocked: status.isUnlocked
                                )
                                .padding(4)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal)
                }
                
                Button {
                    viewModel.showAllAchievements = true
                } label: {
                    Text("view_all_achievements".localized())
                        .font(.captionCustom)
                        .foregroundColor(.accent)
                        .padding(.top, 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Helpers
    
    private func expandableHeader(
        title: String,
        isExpanded: Binding<Bool>
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack {
                Text(title)
                    .font(.titleCustom)
                    .foregroundColor(.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 180 : 0))
            }
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}
