import SwiftUI

struct AvatarStackView: View {
    let avatars: [String] // initials or emoji for demo
    let maxVisible: Int = 5

    var body: some View {
        HStack(spacing: -16) {
            ForEach(avatars.prefix(maxVisible), id: \.self) { avatar in
                Text(avatar)
                    .font(.caption)
                    .frame(width: 40, height: 40)
                    .background(Theme.gradientParty)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Theme.background, lineWidth: 2)
                    )
                    .shadow(color: Theme.partyPurple.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            if avatars.count > maxVisible {
                Text("+\(avatars.count - maxVisible)")
                    .font(.caption)
                    .frame(width: 40, height: 40)
                    .background(Theme.muted)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Sample Usage (Drop this into HomeView or RoomView)
/*
.onAppear {
    AmbientSoundManager.shared.start()
}
.onDisappear {
    AmbientSoundManager.shared.stop()
}

AvatarStackView(avatars: ["👾", "🎧", "😎", "👻", "👽", "🎃"])
*/

