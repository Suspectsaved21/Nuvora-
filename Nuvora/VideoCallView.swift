//
//  VideoCallView.swift
//  Nuvora
//
//  Video call interface with realtime presence integration
//

import SwiftUI

struct VideoCallView: View {
    @StateObject private var viewModel = VideoCallViewModel()
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    let roomId: String
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Video grid
                VideoGridView(
                    participants: viewModel.participants,
                    localVideoEnabled: viewModel.localCameraEnabled,
                    geometry: geometry
                )
                
                // Controls overlay
                VStack {
                    Spacer()
                    
                    // Participant info bar
                    if !viewModel.participants.isEmpty {
                        ParticipantInfoBar(participants: viewModel.participants)
                            .padding(.horizontal)
                    }
                    
                    // Control buttons
                    VideoCallControlsView(
                        cameraEnabled: $viewModel.localCameraEnabled,
                        microphoneEnabled: $viewModel.localMicrophoneEnabled,
                        screenSharing: $viewModel.screenSharing,
                        onEndCall: {
                            Task {
                                await viewModel.leaveCall()
                            }
                        }
                    )
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.joinCall(roomId: roomId, realtimeService: supabaseManager.realtime)
            }
        }
        .onDisappear {
            Task {
                await viewModel.leaveCall()
            }
        }
    }
}

struct VideoGridView: View {
    let participants: [VideoCallParticipant]
    let localVideoEnabled: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        let columns = gridColumns(for: participants.count + 1) // +1 for local video
        
        LazyVGrid(columns: columns, spacing: 8) {
            // Local video
            LocalVideoView(enabled: localVideoEnabled)
                .aspectRatio(16/9, contentMode: .fit)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
            
            // Remote participants
            ForEach(participants) { participant in
                RemoteVideoView(participant: participant)
                    .aspectRatio(16/9, contentMode: .fit)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private func gridColumns(for count: Int) -> [GridItem] {
        let columns: Int
        switch count {
        case 1...2:
            columns = 1
        case 3...4:
            columns = 2
        case 5...9:
            columns = 3
        default:
            columns = 4
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: columns)
    }
}

struct LocalVideoView: View {
    let enabled: Bool
    
    var body: some View {
        ZStack {
            if enabled {
                // Placeholder for actual video feed
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            } else {
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                
                VStack {
                    Image(systemName: "video.slash")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Camera Off")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            
            // Local indicator
            VStack {
                HStack {
                    Spacer()
                    Text("You")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(8)
                }
                Spacer()
            }
        }
    }
}

struct RemoteVideoView: View {
    let participant: VideoCallParticipant
    
    var body: some View {
        ZStack {
            if participant.cameraEnabled {
                // Placeholder for actual video feed
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.green.opacity(0.6), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            } else {
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                
                VStack {
                    Image(systemName: "person.circle")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Camera Off")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            
            // Participant info overlay
            VStack {
                HStack {
                    Spacer()
                    Text(participant.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(8)
                }
                Spacer()
                HStack {
                    if !participant.microphoneEnabled {
                        Image(systemName: "mic.slash")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                    
                    if participant.screenSharing {
                        Image(systemName: "rectangle.on.rectangle")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                .padding(8)
            }
        }
    }
}

struct ParticipantInfoBar: View {
    let participants: [VideoCallParticipant]
    
    var body: some View {
        HStack {
            Image(systemName: "person.2")
                .foregroundColor(.white)
            
            Text("\(participants.count + 1) participants") // +1 for local user
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            // Connection quality indicator
            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    Rectangle()
                        .frame(width: 3, height: CGFloat(4 + index * 2))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }
}

struct VideoCallControlsView: View {
    @Binding var cameraEnabled: Bool
    @Binding var microphoneEnabled: Bool
    @Binding var screenSharing: Bool
    let onEndCall: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Camera toggle
            Button(action: { cameraEnabled.toggle() }) {
                Image(systemName: cameraEnabled ? "video" : "video.slash")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(cameraEnabled ? Color.gray.opacity(0.6) : Color.red)
                    .clipShape(Circle())
            }
            
            // Microphone toggle
            Button(action: { microphoneEnabled.toggle() }) {
                Image(systemName: microphoneEnabled ? "mic" : "mic.slash")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(microphoneEnabled ? Color.gray.opacity(0.6) : Color.red)
                    .clipShape(Circle())
            }
            
            // Screen sharing toggle
            Button(action: { screenSharing.toggle() }) {
                Image(systemName: screenSharing ? "rectangle.on.rectangle" : "rectangle.dashed")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(screenSharing ? Color.blue : Color.gray.opacity(0.6))
                    .clipShape(Circle())
            }
            
            // End call
            Button(action: onEndCall) {
                Image(systemName: "phone.down")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Supporting Types
struct VideoCallParticipant: Identifiable {
    let id: String
    let displayName: String
    let cameraEnabled: Bool
    let microphoneEnabled: Bool
    let screenSharing: Bool
    let joinedAt: Date
}

@MainActor
class VideoCallViewModel: ObservableObject {
    @Published var participants: [VideoCallParticipant] = []
    @Published var localCameraEnabled = true
    @Published var localMicrophoneEnabled = true
    @Published var screenSharing = false
    @Published var isConnected = false
    
    private var realtimeService: RealtimeService?
    private var currentRoomId: String?
    
    func joinCall(roomId: String, realtimeService: RealtimeService?) async {
        self.realtimeService = realtimeService
        self.currentRoomId = roomId
        
        do {
            try await realtimeService?.joinVideoCall(roomId: roomId)
            self.isConnected = true
            
            // Monitor presence changes
            if let service = realtimeService {
                // Convert presence to participants
                updateParticipants(from: service.videoCallParticipants)
            }
        } catch {
            print("Failed to join call: \(error)")
        }
    }
    
    func leaveCall() async {
        do {
            try await realtimeService?.leaveVideoCall()
            self.isConnected = false
            self.participants.removeAll()
        } catch {
            print("Failed to leave call: \(error)")
        }
    }
    
    private func updateParticipants(from presence: [String: VideoCallPresence]) {
        participants = presence.values.map { presence in
            VideoCallParticipant(
                id: presence.userId,
                displayName: "User \(presence.userId.prefix(8))", // In real app, fetch from user profile
                cameraEnabled: presence.cameraEnabled,
                microphoneEnabled: presence.microphoneEnabled,
                screenSharing: presence.screenSharing,
                joinedAt: presence.joinedAt
            )
        }
    }
}

#Preview {
    VideoCallView(roomId: "test-room")
        .environmentObject(SupabaseManager.shared)
}