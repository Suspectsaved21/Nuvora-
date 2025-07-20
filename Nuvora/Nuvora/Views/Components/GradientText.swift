import SwiftUI

struct GradientText: View {
    let text: String
    let font: Font
    var animated: Bool = true

    @State private var animate = false

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(.bold)
            .foregroundColor(.clear)
            .overlay(
                Theme.gradientParty
                    .mask(
                        Text(text)
                            .font(font)
                            .fontWeight(.bold)
                    )
            )
            .scaleEffect(animated ? (animate ? 1.03 : 1.0) : 1.0)
            .shadow(color: Theme.partyPurple.opacity(0.4), radius: animate ? 10 : 0)
            .animation(
                animated
                    ? .easeInOut(duration: 2.4).repeatForever(autoreverses: true)
                    : .default,
                value: animate
            )
            .onAppear {
                if animated {
                    animate = true
                }
            }
    }
}

