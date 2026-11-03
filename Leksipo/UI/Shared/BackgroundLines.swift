//
//  BackgroundLines.swift
//  Leksipo
//
//  Created by Егор Халиков on 23.09.2026.
//

import SwiftUI

struct BackgroundLines: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 100))
                path.addLine(to: CGPoint(x: 200, y: 300))
            }
            .stroke(Color.brown.opacity(0.08), lineWidth: 2)
            
            Circle()
                .fill(Color.brown.opacity(0.03))
                .frame(width: 300, height: 300)
                .offset(x: 200, y: -50)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
