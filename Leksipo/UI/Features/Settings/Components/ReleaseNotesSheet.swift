//
//  ReleaseNoteSheet.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct ReleaseNotesSheet: View {
    private let themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    versionBlock(
                        versionKey: "version_2_10_0",
                        statusKey: "current_version",
                        icon: "crown.fill",
                        iconColor: .accent,
                        items: [
                            "release_notes_2_10_0_1",
                            "release_notes_2_10_0_2",
                            "release_notes_2_10_0_3",
                            "release_notes_2_10_0_4",
                            "release_notes_2_10_0_5",
                            "release_notes_2_10_0_6",
                            "release_notes_2_10_0_7",
                            "release_notes_2_10_0_8",
                            "release_notes_2_10_0_9",
                            "release_notes_2_10_0_10"
                        ]
                    )

                    versionBlock(
                        versionKey: "version_2_9_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_9_0_1",
                            "release_notes_2_9_0_2",
                            "release_notes_2_9_0_3",
                            "release_notes_2_9_0_4",
                            "release_notes_2_9_0_5",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_8_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_8_0_1",
                            "release_notes_2_8_0_2",
                            "release_notes_2_8_0_3",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_7_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_7_0_1",
                            "release_notes_2_7_0_2",
                            "release_notes_2_7_0_3",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_6_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_6_0_1",
                            "release_notes_2_6_0_2",
                            "release_notes_2_6_0_3",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_5_3",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_5_3_1",
                            "release_notes_2_5_3_2",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_5_2",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_5_2_1",
                            "release_notes_2_5_2_2",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_5_1",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_5_1_1",
                            "release_notes_2_5_1_2",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_5_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_5_0_1",
                            "release_notes_2_5_0_2",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_4_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_4_0_1",
                            "release_notes_2_4_0_2",
                            "release_notes_2_4_0_3",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_3_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_3_0_1",
                            "release_notes_2_3_0_2",
                            "release_notes_2_3_0_3",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_2_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_2_0_1",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_1_1",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_1_1_1",
                            "release_notes_2_1_1_2",
                            "release_notes_2_1_1_3",
                            "release_notes_2_1_1_4",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_1_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_1_0_1",
                            "release_notes_2_1_0_2",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_0_1",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_0_1_1",
                            "release_notes_2_0_1_2",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_2_0_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_2_0_0_1",
                            "release_notes_2_0_0_2",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_1_1",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: ["release_notes_1_1_1_1", "release_notes_1_1_1_2"]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_1_0",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_1_1_0_1",
                            "release_notes_1_1_0_2",
                            "release_notes_1_1_0_3",
                            "release_notes_1_1_0_4",
                            "release_notes_1_1_0_5",
                            "release_notes_1_1_0_6",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_0_7",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_1_0_7_1",
                            "release_notes_1_0_7_2",
                            "release_notes_1_0_7_3",
                            "release_notes_1_0_7_4",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_0_6",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_1_0_6_1",
                            "release_notes_1_0_6_2",
                            "release_notes_1_0_6_3",
                            "release_notes_1_0_6_4",
                            "release_notes_1_0_6_5",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_0_5",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_1_0_5_1",
                            "release_notes_1_0_5_2",
                            "release_notes_1_0_5_3",
                            "release_notes_1_0_5_4",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_0_4",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_1_0_4_1",
                            "release_notes_1_0_4_2",
                            "release_notes_1_0_4_3",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_0_3",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_1_0_3_1",
                            "release_notes_1_0_3_2",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_0_2",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_1_0_2_1",
                            "release_notes_1_0_2_2",
                            "release_notes_1_0_2_3",
                            "release_notes_1_0_2_4",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_0_1",
                        statusKey: "previous_version",
                        icon: "clock.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: [
                            "release_notes_1_0_1_1",
                            "release_notes_1_0_1_2",
                            "release_notes_1_0_1_3",
                            "release_notes_1_0_1_4",
                        ]
                    )
                    
                    versionBlock(
                        versionKey: "version_1_0_0",
                        statusKey: "initial_release",
                        icon: "flag.fill",
                        iconColor: themeManager.colors.textSecondary,
                        items: (1...16).map { "release_notes_1_0_0_\($0)" }
                    )
                }
                .padding()
            }
            .background(themeManager.colors.background.ignoresSafeArea())
            .navigationTitle("release_notes".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close_button".localized()) { dismiss() }
                        .foregroundColor(themeManager.colors.accent)
                }
            }
        }
    }
    
    private func versionBlock(
        versionKey: String,
        statusKey: String,
        icon: String,
        iconColor: Color,
        items: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(versionKey.localized())
                    .font(.title3)
                    .foregroundColor(themeManager.colors.textPrimary)
            }
            
            Text(statusKey.localized())
                .font(.captionCustom)
                .foregroundColor(themeManager.colors.textSecondary)
            
            Divider()
                .background(themeManager.colors.stroke)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { key in
                    ReleaseNoteItem(text: key.localized())
                }
            }
        }
    }
}

struct ReleaseNoteItem: View {
    let text: String
    private let themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.caption)
                .foregroundColor(themeManager.colors.accent)
                .frame(width: 20)
            
            Text(text)
                .font(.bodyCustom)
                .foregroundColor(themeManager.colors.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
