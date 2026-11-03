//
//  RootView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct RootView: View {
    @Environment(AppContainer.self) private var container
    @Environment(AppRouter.self) private var router
    private let themeManager = ThemeManager.shared
    private let languageManager = LanguageManager.shared
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var selectedTab: TabItem = TabItem(screen: .cardsGroups)
    @State private var refreshTrigger = false
    @State private var tabBarVisibility = TabBarVisibility()
    
    private var tabs: [TabItem] { TabItem.all }
    
    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            } else {
                mainAppContent
            }
        }
        .environment(tabBarVisibility)
        .preferredColorScheme(themeManager.colorScheme)
        .tint(themeManager.colors.accent)
        .onAppear {
            themeManager.applyNavigationBarAppearance()
            applyPendingRoute()
        }
        .onChange(of: router.pendingRoute) { _, _ in applyPendingRoute() }
        .onChange(of: hasCompletedOnboarding) { _, _ in applyPendingRoute() }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            refreshTrigger.toggle()
        }
    }
    
    private var mainAppContent: some View {
        ZStack(alignment: .bottom) {
            themeManager.colors.background
                .ignoresSafeArea()
            
            Group {
                switch selectedTab.screen {
                case .cardsGroups:
                    GroupsListView(container: container)
                case .solveCards:
                    SolveListView(container: container)
                case .srsReview:
                    SRSOverviewView(container: container)
                case .profile:
                    ProfileView(container: container)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id("\(refreshTrigger)-\(container.dataRevision)")
            
            if tabBarVisibility.isVisible {
                CustomTabBar(tabs: tabs, selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.easeInOut(duration: 0.25), value: tabBarVisibility.isVisible)
        .alert("backup_success_title".localized(), isPresented: Binding(
            get: { container.showRestoreSuccess },
            set: { container.showRestoreSuccess = $0 }
        )) {
            Button("ok".localized()) { container.showRestoreSuccess = false }
        } message: {
            Text("backup_restore_success".localized())
        }
        .overlay(alignment: .top) {
            achievementBanner
        }
    }
    
    private func applyPendingRoute() {
        guard hasCompletedOnboarding, let route = router.pendingRoute else { return }
        switch route {
        case .srs: selectedTab = TabItem(screen: .srsReview)
        }
        router.consume(route)
    }

    @ViewBuilder
    private var achievementBanner: some View {
        if let achievement = container.achievementsService.recentlyUnlocked {
            AchievementNotificationView(achievement: achievement)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: achievement.id) {
                    do { try await Task.sleep(for: .seconds(3)) } catch { return }
                    guard !Task.isCancelled else { return }
                    withAnimation {
                        container.achievementsService.consumeRecentlyUnlocked(id: achievement.id)
                    }
                }
                .zIndex(100)
        }
    }
}
