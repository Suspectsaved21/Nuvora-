import SwiftUI
import AVFoundation

struct HomeView: View {
    @StateObject private var viewModel = RoomViewModel()
    @State private var showCreateDialog = false
    @State private var animateGlow = false
    @State private var showConfetti = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Avatar Stack (Live Friends)
                AvatarStackView(avatars: ["👾", "🎧", "😎", "👻", "👽", "🎃"])
                    .padding(.top, 20)

                ZStack {
                    // MARK: - Floating Glowing Background
                    Circle()
                        .fill(Theme.partyPurple.opacity(0.2))
                        .frame(width: 400, height: 400)
                        .blur(radius: 80)
                        .offset(y: -100)
                        .scaleEffect(animateGlow ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGlow)

                    VStack(spacing: 32) {
                        // MARK: - Hero Section
                        VStack(spacing: 16) {
                            GradientText(
                                text: "House Party",
                                font: .system(size: 48),
                                animated: true
                            )

                            Text("Drop in on friends, have spontaneous conversations, and hang out together like you're in the same room 🎉")
                                .font(.subheadline)
                                .foregroundColor(Theme.mutedForeground)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            PartyButton(
                                title: "Start a House Party",
                                variant: .create,
                                size: .large,
                                action: {
                                    withAnimation {
                                        showCreateDialog = true
                                        showConfetti = true
                                    }
                                    SoundManager.shared.playPop()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        showConfetti = false
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                        .padding(.top, 40)

                        // MARK: - Feature Icons
                        HStack(spacing: 24) {
                            FeatureIcon(label: "Video Chat", systemName: "video.fill")
                            FeatureIcon(label: "Group Hangouts", systemName: "person.3.fill")
                            FeatureIcon(label: "Stay Connected", systemName: "heart.fill")
                        }
                        .foregroundColor(Theme.mutedForeground)
                        .font(.footnote)

                        // MARK: - Room Search + List
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Theme.mutedForeground)
                                TextField("Search for rooms...", text: $viewModel.searchTerm)
                                    .foregroundColor(Theme.foreground)
                            }
                            .padding()
                            .background(Theme.secondary.opacity(0.5))
                            .cornerRadius(12)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(viewModel.filteredRooms) { room in
                                    RoomCardView(room: room) {
                                        viewModel.joinRoom(roomID: room.id)
                                    }
                                }
                            }

                            if viewModel.filteredRooms.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.mutedForeground)
                                    Text("No rooms found. Start your own party!")
                                        .foregroundColor(Theme.mutedForeground)
                                }
                                .padding(.top, 40)
                            }
                        }

                        // MARK: - Quick Actions
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                ActionCard(
                                    title: "Join by Room Code",
                                    subtitle: "Have a private room code?",
                                    buttonTitle: "Enter Code",
                                    icon: "key",
                                    animate: animateGlow
                                )
                                ActionCard(
                                    title: "Invite Friends",
                                    subtitle: "Share with your contacts",
                                    buttonTitle: "Send Invites",
                                    icon: "person.crop.circle.badge.plus",
                                    animate: animateGlow,
                                    inviteAction: shareApp
                                )
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)

                    if showConfetti || viewModel.shouldTriggerConfetti {
                        ConfettiView(show: .constant(true))
                            .transition(.scale)
                    }
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .sheet(isPresented: $showCreateDialog) {
            CreateRoomDialog(isPresented: $showCreateDialog, viewModel: viewModel)
        }
        .overlay(alignment: .top) {
            if let message = viewModel.latestEventMessage {
                Text(message)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .foregroundColor(Theme.foreground)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: message)
            }
        }
        .onAppear {
            animateGlow = true
            AmbientSoundManager.shared.start()
        }
        .onDisappear {
            AmbientSoundManager.shared.stop()
        }
    }

    private func shareApp() {
        let text = "🎉 Join me on Nuvora! It’s like Houseparty, but hotter: https://nuvora.app"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

// MARK: - Feature Icons

private struct FeatureIcon: View {
    let label: String
    let systemName: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemName)
                .frame(width: 24, height: 24)
            Text(label)
        }
    }
}

// MARK: - Action Cards

private struct ActionCard: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let icon: String
    let animate: Bool
    var inviteAction: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.mutedForeground)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.foreground)
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(Theme.mutedForeground)

            PartyButton(
                title: buttonTitle,
                variant: .secondary,
                size: .medium,
                action: {
                    inviteAction?()
                }
            )
        }
        .padding()
        .background(Theme.secondary.opacity(0.4))
        .cornerRadius(16)
        .shadow(color: Theme.partyPurple.opacity(0.2), radius: 10, x: 0, y: 0)
        .scaleEffect(animate ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)
    }
}

