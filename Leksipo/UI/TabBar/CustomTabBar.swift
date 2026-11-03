//
//  CustomTabBar.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct CustomTabBar: View {
    let tabs: [TabItem]
    @Binding var selectedTab: TabItem
    
    @Namespace private var selectionNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(Color.cardBackground)
                .shadow(color: Color.shadowColor, radius: 10, x: 0, y: 4)
        )
        .overlay(
            Capsule()
                .stroke(Color.stroke.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func tabButton(_ tab: TabItem) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(isSelected ? .white : Color.textSecondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.accent)
                            .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

