import SwiftUI

struct AppTourView: View {
    let destination: AppContainer
    let introduce: Bool
    let onFinish: (Bool) -> Void

    @AppStorage("userName") private var userName = ""
    @State private var tour: AppTour?
    @State private var name = ""
    @State private var tabBarVisibility = TabBarVisibility()
    @State private var setupError: String?
    @State private var saveError: String?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if let tour {
                tourContent(tour)
                    .environment(tour.sandbox)
                    .environment(\.appTour, tour)
                    .environment(tabBarVisibility)
                    .modelContainer(tour.model)
                    .onChange(of: tour.exitRequested) { _, requested in
                        if requested { onFinish(false) }
                    }
            } else if let setupError {
                VStack(spacing: 16) {
                    MascotView(pose: .support).frame(height: 90)
                    Text("tour_setup_error".localized()).font(.headline)
                    Text(setupError).font(.caption)
                    Button("close".localized()) { onFinish(false) }
                }
                .multilineTextAlignment(.center)
                .padding()
            } else {
                ProgressView()
            }
        }
        .tint(.accent)
        .interactiveDismissDisabled()
        .task {
            guard tour == nil, setupError == nil else { return }
            do {
                tour = try AppTour(introduce: introduce)
                name = userName
            } catch {
                setupError = error.localizedDescription
            }
        }
        .alert("error_title".localized(), isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("ok".localized(), role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private func tourContent(_ tour: AppTour) -> some View {
        let showsTabBar = tabBarVisibility.isVisible || tour.step == .reviewsTab

        return ZStack(alignment: .bottom) {
            tourScreen(tour, showsTabBar: showsTabBar)

            if showsTabBar, tour.screen != .srsReview {
                tabBar(tour)
            }
        }
        .ignoresSafeArea(.container, edges: showsTabBar ? .bottom : [])
        .allowsHitTesting(tour.step != .introduction)
        .accessibilityHidden(tour.step == .introduction)
        .overlay {
            if tour.step == .introduction {
                introduction(tour)
            }
        }
    }

    private func tourScreen(_ tour: AppTour, showsTabBar: Bool) -> some View {
        VStack(spacing: 0) {
            if tour.step != .introduction {
                VStack(spacing: 8) {
                    TourSpeech(message: tour.step.message,
                               pose: tour.step == .finish ? .celebrate : .support,
                               onSkip: { onFinish(false) })
                    stepActions(tour)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: 640)
            }

            screen(tour)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsTabBar, tour.screen == .srsReview {
                tabBar(tour)
            }
        }
    }

    private func tabBar(_ tour: AppTour) -> some View {
        CustomTabBar(tabs: TabItem.all, selectedTab: Binding(
            get: { TabItem(screen: tour.screen) },
            set: { tour.selectTab($0.screen) }
        ), guidedTab: tour.nextTab)
        .disabled(tour.nextTab == nil)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func screen(_ tour: AppTour) -> some View {
        switch tour.screen {
        case .cardsGroups: GroupsListView(container: tour.sandbox)
        case .solveCards: SolveListView(container: tour.sandbox)
        case .srsReview: SRSOverviewView(container: tour.sandbox)
        case .profile: ProfileView(container: tour.sandbox)
        }
    }

    private func introduction(_ tour: AppTour) -> some View {
        ZStack {
            Color.black.opacity(0.32).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    TourSpeech(message: tour.step.message, pose: .welcome)
                    TextField("onboarding_name_placeholder".localized(), text: $name)
                        .textContentType(.nickname)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 12))
                        .onSubmit { startAfterIntroduction(tour) }

                    Button("tour_start".localized()) { startAfterIntroduction(tour) }
                        .buttonStyle(.borderedProminent)
                        .disabled(trimmedName.isEmpty)
                    Button("tour_skip".localized()) { onFinish(false) }
                        .font(.captionCustom)
                }
                .padding(18)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 24))
                .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .defaultScrollAnchor(.center)
            .frame(maxWidth: 520)
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func startAfterIntroduction(_ tour: AppTour) {
        guard !trimmedName.isEmpty else { return }
        userName = trimmedName
        tour.advance(from: .introduction, to: .createGroup)
    }

    @ViewBuilder
    private func stepActions(_ tour: AppTour) -> some View {
        switch tour.step {
        case .profile:
            Button("tour_next".localized()) { tour.advance(from: .profile, to: .finish) }
                .buttonStyle(.borderedProminent)
        case .finish:
            ViewThatFits(in: .horizontal) {
                HStack { finishButtons(tour) }
                VStack { finishButtons(tour) }
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func finishButtons(_ tour: AppTour) -> some View {
        Button("tour_save_group".localized()) {
            do {
                try tour.saveGroup(to: destination)
                onFinish(true)
            } catch {
                saveError = error.localizedDescription
            }
        }
        .buttonStyle(.borderedProminent)
        Button("tour_finish_without_saving".localized()) { onFinish(false) }
            .buttonStyle(.bordered)
    }
}

struct TourSpeech: View {
    let message: String
    var pose: MascotPose = .support
    var onSkip: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            MascotView(pose: pose)
                .frame(width: 58, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("tour_lexi".localized())
                        .font(.captionCustom.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                    Spacer(minLength: 6)
                    if let onSkip {
                        Button("tour_skip".localized(), action: onSkip)
                            .font(.captionCustom)
                    }
                }
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.shadowColor, radius: 4, y: 2)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.cardBackground)
                            .frame(width: 10, height: 10)
                            .rotationEffect(.degrees(45))
                            .offset(x: -4)
                    }
            }
        }
    }
}
