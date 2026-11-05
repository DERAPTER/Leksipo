import SwiftUI

struct ProfileView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appTour) private var tour
    @AppStorage("userName") private var userName = ""
    @AppStorage("profileAvatarBackground") private var avatarBackground = LexiAvatarBackground.sand
    @AppStorage("profileAvatarHeadwear") private var avatarHeadwear = LexiAvatarHeadwear.none
    @AppStorage("profileAvatarNeckwear") private var avatarNeckwear = LexiAvatarNeckwear.none
    @AppStorage("profileAvatarGlasses") private var avatarGlasses = LexiAvatarGlasses.none
    @AppStorage("profileAvatarEarAccessory") private var avatarEarAccessory = LexiAvatarEarAccessory.none
    @AppStorage("profileAvatarHeadphones") private var avatarHeadphones = LexiAvatarHeadphones.none
    @AppStorage("profileAvatarPreviouslyEquippedOptions") private var previouslyEquippedOptions: String?
    @State private var viewModel: ProfileViewModel
    @State private var showCustomization = false
    private let onStartTour: (() -> Void)?

    init(container: AppContainer, onStartTour: (() -> Void)? = nil) {
        self.onStartTour = onStartTour
        _viewModel = State(initialValue: ProfileViewModel(statsRepository: container.statsRepository,
            cardRepository: container.cardRepository, groupRepository: container.groupRepository,
            achievementsService: container.achievementsService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if let error = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error).foregroundStyle(.red)
                            Button("retry_action".localized()) { viewModel.load() }
                        }
                    }
                    if viewModel.hasLoaded {
                        languagesSection
                        weekSection
                            .tourHighlight(tour?.step == .profile, cornerRadius: 18)
                            .disabled(tour != nil)
                        attentionSection
                            .disabled(tour != nil)
                        achievementsSection
                            .disabled(tour != nil)
                    }
                }
                .padding()
                .padding(.bottom, 110)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("profile_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if tour == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink { SettingsView(container: container, onStartTour: onStartTour) } label: { Image(systemName: "gearshape") }
                            .accessibilityLabel("settings_title".localized())
                    }
                }
            }
            .onAppear { viewModel.load() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { viewModel.load() } }
            .refreshable { viewModel.load() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in viewModel.load() }
            .sheet(isPresented: $viewModel.showAllAchievements) { AllAchievementsSheet(achievements: viewModel.achievements) }
            .sheet(isPresented: $viewModel.showHistory) { ProgressHistoryView(days: viewModel.history) }
            .sheet(isPresented: $showCustomization) {
                ProfileCustomizationView(name: userName, appearance: avatarAppearance, access: avatarAccess) { name, appearance in
                    // Keep the original outfit available even after the user changes it.
                    if previouslyEquippedOptions == nil {
                        previouslyEquippedOptions = avatarAppearance.gatedOptionIDs.sorted().joined(separator: ",")
                    }
                    userName = name
                    avatarBackground = appearance.background
                    avatarHeadwear = appearance.headwear
                    avatarNeckwear = appearance.neckwear
                    avatarGlasses = appearance.glasses
                    avatarEarAccessory = appearance.earAccessory
                    avatarHeadphones = appearance.headphones
                }
            }
        }
    }

    private var avatarAppearance: LexiAvatarAppearance {
        LexiAvatarAppearance(background: avatarBackground, headwear: avatarHeadwear, neckwear: avatarNeckwear,
                             glasses: avatarGlasses, earAccessory: avatarEarAccessory, headphones: avatarHeadphones)
    }

    private var avatarAccess: LexiAvatarAccess {
        let previouslyEquippedIDs = previouslyEquippedOptions.map { Set($0.split(separator: ",").map(String.init)) }
        return LexiAvatarAccess(
            unlockedAchievementIDs: Set(viewModel.achievements.lazy.filter(\.isUnlocked).map(\.id)),
            previouslyEquippedOptionIDs: avatarAppearance.gatedOptionIDs.union(previouslyEquippedIDs ?? [])
        )
    }

    private var header: some View {
        VStack(spacing: 12) {
            LexiAvatarView(appearance: avatarAppearance, size: 128)
            Text(userName.isEmpty ? "learner".localized() : userName)
                .font(.titleCustom)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 22))
        .overlay(alignment: .topTrailing) {
            Button {
                showCustomization = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.appBackground, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("profile_edit".localized())
            .disabled(tour != nil)
            .tourHighlight(tour?.step == .profile, cornerRadius: 22)
            .padding(12)
        }
    }

    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("progress_languages")
            if viewModel.languages.isEmpty {
                Text("progress_languages_empty".localized()).foregroundStyle(Color.textSecondary)
            }
            ForEach(viewModel.languages) { item in
                VStack(alignment: .leading, spacing: 12) {
                    NavigationLink {
                        ProgressCardListView(viewModel: viewModel, pair: item.pair, filter: .all)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.pair.displayName).font(.bodyCustom.weight(.semibold))
                                Text(String(format: "progress_cards_count".localized(), item.cards.count)).font(.captionCustom)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(.plain)
                    languageBar(item)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 16) { languageLinks(item) }
                        VStack(alignment: .leading, spacing: 8) { languageLinks(item) }
                    }
                }
                .padding()
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
            }
            if !viewModel.languages.isEmpty {
                Text("progress_interval_hint".localized()).font(.captionCustom).foregroundStyle(Color.textSecondary)
            }
        }
        .foregroundStyle(Color.textPrimary)
    }

    private func languageBar(_ item: ProfileViewModel.LanguageProgress) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Color.stroke.frame(width: geometry.size.width * Double(item.newCount) / Double(max(1, item.cards.count)))
                Color.accent.opacity(0.5).frame(width: geometry.size.width * Double(item.learningCount) / Double(max(1, item.cards.count)))
                Color.accent.frame(width: geometry.size.width * Double(item.longTermCount) / Double(max(1, item.cards.count)))
            }
        }
        .frame(height: 8).clipShape(Capsule()).accessibilityHidden(true)
    }

    @ViewBuilder
    private func languageLinks(_ item: ProfileViewModel.LanguageProgress) -> some View {
        ForEach([ProfileViewModel.CardFilter.new, .learning, .longTerm]) { filter in
            NavigationLink { ProgressCardListView(viewModel: viewModel, pair: item.pair, filter: filter) } label: {
                let count = filter == .new ? item.newCount : (filter == .learning ? item.learningCount : item.longTermCount)
                Text("\(count) · \(filter.title)").font(.captionCustom).foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var weekSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("progress_week")
                Spacer()
                Button("progress_history".localized()) { viewModel.showHistory = true }.font(.captionCustom)
            }
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(viewModel.week) { day in
                    VStack(spacing: 6) {
                        Text("\(day.correctAnswers)").font(.captionCustom).foregroundStyle(Color.textSecondary)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(day.correctAnswers > 0 ? Color.accent : Color.stroke.opacity(0.4))
                            .frame(height: max(4, 72 * Double(day.correctAnswers) / Double(max(1, viewModel.week.map(\.correctAnswers).max() ?? 1))))
                        Text(day.date.formatted(.dateTime.weekday(.abbreviated).locale(LanguageManager.shared.currentLanguage.locale)))
                            .font(.captionCustom).foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.date.formatted(date: .abbreviated, time: .omitted)), \(String(format: "progress_correct_count".localized(), day.correctAnswers))")
                }
            }
            Text(String(format: "progress_correct_count".localized(), viewModel.weeklyCorrectAnswers)).font(.bodyCustom.weight(.semibold))
            Text(String(format: "progress_reviews_count".localized(), viewModel.weeklySRSReviews))
                .font(.captionCustom).foregroundStyle(Color.textSecondary)
        }
        .padding().foregroundStyle(Color.textPrimary)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("progress_attention")
            if viewModel.attentionCount > 0 {
                NavigationLink { ProgressCardListView(viewModel: viewModel, pair: nil, filter: .attention) } label: {
                    HStack {
                        Text(String(format: "progress_attention_count".localized(), viewModel.attentionCount))
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.bodyCustom)
                }
            } else {
                Text("progress_attention_empty".localized()).font(.bodyCustom).foregroundStyle(Color.textSecondary)
            }
        }
        .padding().background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("progress_next_achievement")
            if let next = viewModel.nextAchievement { AchievementCard(status: next) }
            else { Text("progress_achievements_complete".localized()).foregroundStyle(Color.textSecondary) }
            if let latest = viewModel.latestAchievement {
                HStack(spacing: 8) {
                    AchievementArtworkView(achievement: latest.achievement, size: 32)
                    Text("\("progress_latest_achievement".localized()): \(latest.achievement.title)")
                        .font(.captionCustom).foregroundStyle(Color.textSecondary)
                }
            }
            Button("view_all_achievements".localized()) { viewModel.showAllAchievements = true }.font(.bodyCustom)
        }
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(key.localized()).font(.titleCustom).foregroundStyle(Color.textPrimary)
    }
}
