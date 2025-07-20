import SwiftUI

struct RoomCardView: View {
    let room: Room
    let onJoin: () -> Void

    @State private var showEmoji = true
    @State private var currentEmoji: String = ""
    @State private var isJoining = false

    private let emojiCycle = ["🎉", "💃", "🎮", "🎤", "🎧", "🥳"]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                if showEmoji {
                    Text(currentEmoji)
                        .font(.largeTitle)
                        .transition(.scale)
                        .padding(.trailing, 4)
                        .onAppear {
                            cycleEmoji()
                        }
                }

                HStack {
                    Text(room.name)
                        .font(.headline)
                        .foregroundColor(Theme.foreground)
                    if room.isPrivate {
                        Image(systemName: "lock.fill")
                            .foregroundColor(Theme.mutedForeground)
                    }
                }

                Text("\(room.participants)/\(room.maxParticipants) people")
                    .font(.subheadline)
                    .foregroundColor(Theme.mutedForeground)

                HStack(spacing: -8) {
                    ForEach(0..<min(room.participants, 4), id: \.self) { _ in
                        Circle()
                            .fill(LinearGradient(colors: [Theme.partyPurple, Theme.partyPink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Theme.background, lineWidth: 2))
                    }

                    if room.participants > 4 {
                        Text("+\(room.participants - 4)")
                            .font(.caption)
                            .frame(width: 32, height: 32)
                            .background(Theme.muted)
                            .clipShape(Circle())
                    }
                }

                HStack {
                    MoodSticker(mood: room.mood)

                    Spacer()

                    PartyButton(
                        title: room.participants >= room.maxParticipants ? "Full" : "Join",
                        variant: .join,
                        size: .small,
                        action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isJoining = true
                            }
                            SoundManager.shared.playPop()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                onJoin()
                            }
                        },
                        disabled: room.participants >= room.maxParticipants
                    )
                }
            }
            .padding()
            .background(Theme.card.opacity(0.4))
            .cornerRadius(20)
            .shadow(color: Theme.partyPurple.opacity(isJoining ? 0.5 : 0.2), radius: isJoining ? 20 : 8)
            .scaleEffect(isJoining ? 1.05 : 1.0)
            .animation(.spring(), value: isJoining)
        }
    }

    private func cycleEmoji() {
        Task {
            while true {
                await MainActor.run {
                    withAnimation {
                        currentEmoji = emojiCycle.randomElement() ?? "🎉"
                    }
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }
}

struct MoodSticker: View {
    let mood: RoomMood

    var body: some View {
        Text(mood.rawValue)
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.partyBlue.opacity(0.3))
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

