//
//  GroupsListView.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct GroupsListView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.appTour) private var tour
    @State private var viewModel: GroupsListViewModel
    
    @State private var showAddGroupSheet = false
    @State private var showImportSheet = false
    @State private var groupToEdit: CardGroup?
    @State private var cardToEdit: Card?
    @State private var groupToDelete: CardGroup?
    @State private var showDeleteGroupAlert = false
    @State private var addCardToGroup: CardGroup?
    
    init(container: AppContainer) {
        _viewModel = State(initialValue: GroupsListViewModel(
            cardRepository: container.cardRepository,
            groupRepository: container.groupRepository,
            achievementsService: container.achievementsService
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.displayItems) { item in
                        GroupRowView(
                            item: item,
                            viewModel: viewModel,
                            onEdit: handleEdit,
                            onDelete: handleDelete,
                            onEditCard: { cardToEdit = $0 },
                            onAddCard: { addCardToGroup = $0 }
                        )
                        .disabled(tour != nil && (tour?.step != .addCard || item.userGroup?.id != tour?.groupID))
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("groups_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showAddGroupSheet = true
                        } label: {
                            Label("add_new_group".localized(), systemImage: "folder.badge.plus")
                        }
                        
                        if tour == nil {
                            Button {
                                showImportSheet = true
                            } label: {
                                Label("import_groups".localized(), systemImage: "square.and.arrow.down")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.accent)
                            .padding(tour?.step == .createGroup ? 6 : 0)
                            .tourHighlight(tour?.step == .createGroup, cornerRadius: 12)
                    }
                    .accessibilityLabel("tour_add_menu".localized())
                    .disabled(tour != nil && tour?.step != .createGroup)
                }
            }
            .task { viewModel.load() }
            .refreshable { viewModel.load() }
            .sheet(isPresented: $showAddGroupSheet) {
                AddGroupSheet(viewModel: viewModel, isPresented: $showAddGroupSheet)
            }
            .sheet(isPresented: $showImportSheet) {
                ImportDataView(container: container, onComplete: { viewModel.load() })
            }
            .sheet(item: $groupToEdit) { group in
                EditGroupView(
                    group: group,
                    groupRepository: container.groupRepository,
                    onComplete: { viewModel.load() }
                )
            }
            .sheet(item: $cardToEdit) { card in
                EditCardView(
                    card: card,
                    cardRepository: container.cardRepository,
                    groupRepository: container.groupRepository,
                    onComplete: { viewModel.load() }
                )
            }
            .sheet(item: $addCardToGroup) { group in
                AddCardSheet(
                    group: group,
                    cardRepository: container.cardRepository,
                    groupRepository: container.groupRepository,
                    achievementsService: container.achievementsService,
                    onComplete: {
                        viewModel.load()
                        tour?.advance(from: .addCard, to: .practiceTab)
                    }
                )
            }
            .alert("delete_group_confirmation".localized(), isPresented: $showDeleteGroupAlert) {
                Button("cancel".localized(), role: .cancel) { groupToDelete = nil }
                Button("delete".localized(), role: .destructive) {
                    if let group = groupToDelete {
                        try? viewModel.deleteGroup(group)
                    }
                    groupToDelete = nil
                }
            } message: {
                if let group = groupToDelete {
                    Text(String(format: "delete_group_message_format".localized(), group.name))
                }
            }
        }
    }
    
    private var addGroupButton: some View {
        Button {
            showAddGroupSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("add_new_group".localized())
                    .font(.bodyCustom)
            }
            .foregroundColor(.accent)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func handleEdit(_ group: CardGroup) {
        groupToEdit = group
    }
    
    private func handleDelete(_ group: CardGroup) {
        groupToDelete = group
        showDeleteGroupAlert = true
    }
}
