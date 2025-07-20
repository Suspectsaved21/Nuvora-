import SwiftUI

struct ConfettiView: View {
    @Binding var show: Bool

    var body: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { i in
                Circle()
                    .fill(randomColor())
                    .frame(width: 8, height: 8)
                    .opacity(show ? 1 : 0)
                    .offset(x: CGFloat.random(in: -100...100),
                            y: show ? CGFloat.random(in: 100...500) : 0)
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .animation(.interpolatingSpring(stiffness: 50, damping: 10).delay(Double(i) * 0.03), value: show)
            }
        }
        .allowsHitTesting(false)
    }

    private func randomColor() -> Color {
        let colors = [Theme.partyPink, Theme.partyPurple, Theme.partyBlue]
        return colors.randomElement() ?? .pink
    }
}

