//
//  EmptyGroupView.swift
//  English Words
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct EmptyGroupView: View {
    let groupTitle: String
    let onAddFirstCard: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            MascotView(pose: .idle)
                .frame(width: 180, height: 180)
                .padding(.bottom, 8)
            
            Text("empty_group_title".localized())
                .font(.largeTitleCustom)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(String(format: "empty_group_message".localized(), groupTitle))
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onAddFirstCard) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("add_first_card".localized())
                        .font(.bodyCustom.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accent)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.top, 16)
            
            Button(action: onDismiss) {
                Text("back_to_groups".localized())
                    .font(.bodyCustom)
                    .foregroundColor(.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            
            Spacer()
        }
    }
}
