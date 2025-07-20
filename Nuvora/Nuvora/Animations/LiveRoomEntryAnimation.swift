import SwiftUI

struct LiveRoomEntryAnimation: View {
    let emoji: String
    @State private var animate = false

    var body: some View {
        Text(emoji)
            .font(.system(size: 100))
            .scaleEffect(animate ? 1.0 : 0.1)
            .rotationEffect(.degrees(animate ? 0 : -30))
            .offset(y: animate ? 0 : -300)
            .opacity(animate ? 1 : 0)
            .animation(.interpolatingSpring(stiffness: 100, damping: 10), value: animate)
            .onAppear {
                animate = true
            }
    }
}
//
//  LiveRoomEntryAnimation.swift
//  Nuvora
//
//  Created by Kenny Pierrot on 16/07/2025.
//

