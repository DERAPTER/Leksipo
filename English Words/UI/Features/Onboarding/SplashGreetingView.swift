//
//  SplashGreetingView.swift
//  English Words
//
//  Created by Егор Халиков on 23.10.2026.
//

import SwiftUI

struct SplashGreetingView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var isVisible = false
    
    // Определяем время суток
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        let nameText = userName.isEmpty ? "" : ", \(userName)"
        
        switch hour {
        case 5..<12:
            return "greeting_morning".localized() + nameText
        case 12..<18:
            return "greeting_day".localized() + nameText
        case 18..<23:
            return "greeting_evening".localized() + nameText
        default:
            return "greeting_night".localized() + nameText
        }
    }
    
    var body: some View {
        ZStack {
            // Фон приложения
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                MascotView(pose: .welcome)
                    .frame(width: 220, height: 220)

                if hasCompletedOnboarding {
                    // Если пользователь уже знаком с приложением — здороваемся
                    Text(greetingText)
                        .font(.largeTitleCustom)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
            HapticService.shared.lightImpact()
        }
    }
}
