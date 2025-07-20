import SwiftUI

struct StatusBanner: View {
    let message: String
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            Text(message)
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .foregroundColor(Theme.foreground)
                .cornerRadius(12)
                .shadow(radius: 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: isVisible)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            isVisible = false
                        }
                    }
                }
        }
    }
}
//
//  StatusBanner.swift
//  Nuvora
//
//  Created by Kenny Pierrot on 16/07/2025.
//

