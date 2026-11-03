//
//  GoalEditorSheet.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct GoalEditorSheet: View {
    let currentGoal: Int
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var goalValue: Double
    
    init(currentGoal: Int, onSave: @escaping (Int) -> Void) {
        self.currentGoal = currentGoal
        self.onSave = onSave
        _goalValue = State(initialValue: Double(currentGoal))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                header
                
                circularSlider
                
                Spacer()
                
                saveButton
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized()) { dismiss() }
                }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.accent)
            Text("daily_goal".localized())
                .font(.largeTitleCustom)
                .foregroundColor(.textPrimary)
            Text("tap_to_change_goal".localized())
                .font(.bodyCustom)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
    
    private var circularSlider: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.stroke, lineWidth: 12)
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: goalValue / 100)
                    .stroke(Color.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 160, height: 160)
                
                Text("\(Int(goalValue))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            
            VStack(spacing: 8) {
                Slider(value: $goalValue, in: 1...100, step: 1)
                    .tint(.accent)
                
                HStack {
                    Text("1").font(.caption).foregroundColor(.textSecondary)
                    Spacer()
                    Text("50").font(.caption).foregroundColor(.textSecondary)
                    Spacer()
                    Text("100").font(.caption).foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var saveButton: some View {
        Button {
            onSave(Int(goalValue))
            dismiss()
        } label: {
            Text("save".localized())
                .font(.bodyCustom.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accent)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }
}
