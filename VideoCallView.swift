import SwiftUI
import AVFoundation
import WebRTC

struct VideoCallView: View {
    let room: Room
    let onDismiss: () -> Void
    
    @StateObject private var webRTCManager = WebRTCManager()
    @StateObject private var realtimeService = RealtimeService.shared
    @State private var participants: [Participant] = []
    @State private var isMuted = false
    @State private var isVideoEnabled = true
    @State private var showingChat = false
    @State private var unreadMessages = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Header
                headerView
                
                // Video Grid
                videoGridView
                
                Spacer()
                
                // Controls
                controlsView
            }
        }
        .onAppear {
            setupVideoCall()
        }
        .onDisappear {
            leaveCall()
        }
        .sheet(isPresented: $showingChat) {
            ChatView(roomId: room.id)
                .onAppear {
                    unreadMessages = 0
                }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(room.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(participants.count) participants")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: { showingChat = true }) {
                ZStack {
                    Image(systemName: "message.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if unreadMessages > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(min(unreadMessages, 99))")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                            .offset(x: 12, y: -12)
                    }
                }
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
    
    private var videoGridView: some View {
        GeometryReader { geometry in
            let columns = gridColumns(for: participants.count)
            let itemWidth = (geometry.size.width - CGFloat(columns - 1) * 8) / CGFloat(columns)
            let itemHeight = itemWidth * 0.75 // 4:3 aspect ratio
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
                ForEach(participants) { participant in
                    ParticipantVideoView(
                        participant: participant,
                        width: itemWidth,
                        height: itemHeight
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 30) {
            // Mute Button
            Button(action: toggleMute) {
                Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isMuted ? Color.red : Color.white.opacity(0.2))
                    )
            }
            
            // Video Button
            Button(action: toggleVideo) {
                Image(systemName: isVideoEnabled ? "video.fill" : "video.slash.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isVideoEnabled ? Color.white.opacity(0.2) : Color.red)
                    )
            }
            
            // End Call Button
            Button(action: onDismiss) {
                Image(systemName: "phone.down.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.red)
                    )
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Functions
    
    private func setupVideoCall() {
        Task {
            await webRTCManager.setupLocalMedia()
            await realtimeService.joinRoom(room.id)
            
            // Listen for participants
            realtimeService.onParticipantsChanged = { newParticipants in
                Task { @MainActor in
                    participants = newParticipants
                }
            }
            
            // Listen for new messages (for unread count)
            realtimeService.onMessageReceived = { _ in
                Task { @MainActor in
                    if !showingChat {
                        unreadMessages += 1
                    }
                }
            }
        }
    }
    
    private func leaveCall() {
        Task {
            await webRTCManager.disconnect()
            await realtimeService.leaveRoom(room.id)
        }
    }
    
    private func toggleMute() {
        isMuted.toggle()
        webRTCManager.setAudioEnabled(!isMuted)
    }
    
    private func toggleVideo() {
        isVideoEnabled.toggle()
        webRTCManager.setVideoEnabled(isVideoEnabled)
    }
    
    private func gridColumns(for participantCount: Int) -> Int {
        switch participantCount {
        case 1:
            return 1
        case 2:
            return 2
        case 3...4:
            return 2
        case 5...9:
            return 3
        default:
            return 4
        }
    }
}

struct ParticipantVideoView: View {
    let participant: Participant
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // Video View Placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: width, height: height)
                .cornerRadius(8)
            
            // Participant Info Overlay
            VStack {
                Spacer()
                
                HStack {
                    Text(participant.name)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.6))
                        )
                    
                    Spacer()
                    
                    if participant.isMuted {
                        Image(systemName: "mic.slash.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                            )
                    }
                }
                .padding(8)
            }
        }
    }
}

// MARK: - WebRTC Manager

@MainActor
class WebRTCManager: ObservableObject {
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var peerConnection: RTCPeerConnection?
    
    func setupLocalMedia() async {
        // Setup local video and audio tracks
        // This is a simplified implementation
        print("Setting up local media...")
    }
    
    func setAudioEnabled(_ enabled: Bool) {
        localAudioTrack?.isEnabled = enabled
    }
    
    func setVideoEnabled(_ enabled: Bool) {
        localVideoTrack?.isEnabled = enabled
    }
    
    func disconnect() async {
        peerConnection?.close()
        print("Disconnected from WebRTC")
    }
}

// MARK: - Models

struct Participant: Identifiable {
    let id: String
    let name: String
    let isMuted: Bool
    let isVideoEnabled: Bool
}

#Preview {
    VideoCallView(
        room: Room(
            id: "1",
            name: "Sample Room",
            description: "A sample room for preview",
            createdBy: "user1",
            createdAt: Date(),
            maxParticipants: 10,
            isPrivate: false
        )
    ) {
        // Dismiss action
    }
}
