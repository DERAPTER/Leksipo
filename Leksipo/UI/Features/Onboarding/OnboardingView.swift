//
//  OnboardingView.swift
//  Leksipo
//
//  Created by Егор Халиков on 22.10.2026.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    
    @AppStorage("userName") private var savedName: String = ""
    @State private var nameInput: String = ""
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "person.fill",
            title: "onboarding_name_title".localized(),
            description: "onboarding_name_desc".localized(),
            color: .blue,
            isNameEntry: true // <-- Флаг для первого экрана
        ),
        OnboardingPage(
            icon: "rectangle.stack.fill",
            title: "onboarding_2_title".localized(),
            description: "onboarding_2_desc".localized(),
            color: .green,
            isNameEntry: false
        ),
        OnboardingPage(
            icon: "clock.arrow.circlepath",
            title: "onboarding_3_title".localized(),
            description: "onboarding_3_desc".localized(),
            color: .orange,
            isNameEntry: false
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "onboarding_4_title".localized(),
            description: "onboarding_4_desc".localized(),
            color: .purple,
            isNameEntry: false
        )
    ]
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Кнопка пропуска (не показываем на экране с именем, чтобы он ввел его)
                HStack {
                    Spacer()
                    if currentPage != 0 {
                        Button {
                            finishOnboarding()
                        } label: {
                            Text("onboarding_skip".localized())
                                .font(.bodyCustom)
                                .foregroundColor(.textSecondary)
                        }
                        .padding()
                        .opacity(currentPage == pages.count - 1 ? 0 : 1)
                    } else {
                        // Пустое место, чтобы верстка не прыгала
                        Color.clear.frame(width: 60, height: 40)
                    }
                }
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.accent : Color.stroke)
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    Button {
                        if currentPage == pages.count - 1 {
                            finishOnboarding()
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "onboarding_start".localized() : "onboarding_next".localized())
                            .font(.bodyCustom.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentPage == 0 && nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.accent)
                            .cornerRadius(16)
                    }
                    .disabled(currentPage == 0 && nameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Page View
    
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            if page.isNameEntry {
                MascotView(pose: .welcome)
                    .frame(width: 200, height: 200)
            } else {
                ZStack {
                    Circle()
                        .fill(page.color.opacity(0.15))
                        .frame(width: 200, height: 200)

                    Image(systemName: page.icon)
                        .font(.system(size: 80))
                        .foregroundColor(page.color)
                }
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitleCustom)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text(page.description)
                    .font(.bodyCustom)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
                
                if page.isNameEntry {
                    // Поле ввода имени
                    TextField("onboarding_name_placeholder".localized(), text: $nameInput)
                        .font(.bodyCustom)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.stroke, lineWidth: 1)
                        )
                        .padding(.horizontal, 32)
                        .padding(.top, 10)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
            }
            
            Spacer()
            Spacer()
        }
    }
    
    private func finishOnboarding() {
        // Сохраняем имя, если оно введено (на всякий случай)
        let trimmedName = nameInput.trimmingCharacters(in: .whitespaces)
        if !trimmedName.isEmpty {
            savedName = trimmedName
        }
        onFinish()
    }
}

// MARK: - Model

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isNameEntry: Bool
}

