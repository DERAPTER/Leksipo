//
//  SolveListView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct SolveListView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.appTour) private var tour
    @State private var viewModel: SolveListViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    init(container: AppContainer) {
        _viewModel = State(initialValue: SolveListViewModel(
            cardRepository: container.cardRepository,
            groupRepository: container.groupRepository,
            sessionStore: container.solveSessionStore
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(visibleItems) { item in
                        NavigationLink {
                            SolveView(
                                key: item.key,
                                title: item.name,
                                container: container
                            )
                        } label: {
                            GroupSolveCardView(item: item)
                        }
                        .buttonStyle(.plain)
                        .tourHighlight(tour?.step == .choosePractice)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("choose_group".localized())
            .navigationBarTitleDisplayMode(.inline)
            .task { viewModel.load() }
            .refreshable { viewModel.load() }
            .onAppear { viewModel.load() }
        }
    }

    private var visibleItems: [SolveListViewModel.GroupItem] {
        guard let tour else { return viewModel.items }
        guard let groupID = tour.groupID else { return [] }
        return viewModel.items.filter { $0.key == .user(groupID) }
    }
}
