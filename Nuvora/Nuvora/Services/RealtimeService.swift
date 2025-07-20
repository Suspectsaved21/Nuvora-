import Foundation
import Supabase
import Combine

/// Comprehensive real-time service for presence and room management
@MainActor
class RealtimeService: ObservableObject {
    static let shared = RealtimeService()
    
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var activeRooms: [String: RealtimeChannelV2] = [:]
    
    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }
    
    private var presenceChannels: [String: RealtimeChannelV2] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupConnectionListener()
    }
    
    private func setupConnectionListener() {
        // Monitor Supabase manager initialization
        SupabaseManager.shared.$isInitialized
            .sink { [weak self] isInitialized in
                if isInitialized {
                    Task { @MainActor in
                        await self?.connect()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Management
    
    func connect() async {
        guard let client = client else {
            print("❌ Cannot connect: Supabase client not initialized")
            return
        }
        
        do {
            try await client.realtimeV2.connect()
            self.isConnected = true
            self.connectionError = nil
            print("✅ Realtime connected")
        } catch {
            self.isConnected = false
            self.connectionError = error.localizedDescription
            print("❌ Realtime connection failed: \(error)")
        }
    }
    
    func disconnect() async {
        guard let client = client else { return }
        
        await client.realtimeV2.disconnect()
        self.isConnected = false
        self.activeRooms.removeAll()
        self.presenceChannels.removeAll()
        print("👋 Realtime disconnected")
    }
    
    // MARK: - Room Management
    
    /// Join a room with presence tracking
    func joinRoom(_ roomId: String, userMood: RoomMood) async throws -> RealtimeChannelV2 {
        guard let client = client else {
            throw RealtimeError.clientNotInitialized
        }
        
        // Leave existing room if any
        await leaveCurrentRooms()
        
        let channelName = "room:\(roomId)"
        let channel = client.realtimeV2.channel(channelName)
        
        // Setup presence tracking
        struct PresenceState: Codable {
            let userId: String
            let mood: String
            let joinedAt: String
        }
        
        let presenceState = PresenceState(
            userId: AuthService.shared.currentUser?.id.uuidString ?? "anonymous",
            mood: userMood.rawValue,
            joinedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            // Subscribe to channel
            let status = try await channel.subscribe()
            guard status == .subscribed else {
                throw RealtimeError.subscriptionFailed
            }
            
            // Track presence
            let trackStatus = try await channel.track(presenceState)
            guard trackStatus == .ok else {
                throw RealtimeError.subscriptionFailed
            }
            
            // Store channel reference
            self.activeRooms[roomId] = channel
            self.presenceChannels[roomId] = channel
            
            print("✅ Joined room: \(roomId) with mood: \(userMood.rawValue)")
            return channel
            
        } catch {
            print("❌ Failed to join room: \(error)")
            throw error
        }
    }
    
    /// Leave a specific room
    func leaveRoom(_ roomId: String) async {
        guard let channel = activeRooms[roomId] else { return }
        
        do {
            _ = try await channel.untrack()
            try await channel.unsubscribe()
        } catch {
            print("❌ Error leaving room \(roomId): \(error)")
        }
        
        self.activeRooms.removeValue(forKey: roomId)
        self.presenceChannels.removeValue(forKey: roomId)
        
        print("👋 Left room: \(roomId)")
    }
    
    /// Leave all current rooms
    func leaveCurrentRooms() async {
        for (roomId, _) in activeRooms {
            await leaveRoom(roomId)
        }
    }
    
    // MARK: - Presence Management
    
    /// Listen to presence changes in a room
    func listenToPresence(in roomId: String, onChange: @escaping ([String: RoomMood]) -> Void) {
        guard let channel = presenceChannels[roomId] else {
            print("❌ No presence channel found for room: \(roomId)")
            return
        }
        
        // Handle presence sync (full state)
        channel.onPresenceSync { [weak self] states in
            Task { @MainActor in
                let users = self?.parsePresenceStates(states) ?? [:]
                onChange(users)
            }
        }
        
        // Handle presence join
        channel.onPresenceJoin { [weak self] newPresences in
            print("👋 User joined room: \(roomId)")
            Task { @MainActor in
                // Get current state and notify
                if let channel = self?.presenceChannels[roomId] {
                    let currentState = channel.presenceState()
                    let users = self?.parsePresenceStates(currentState) ?? [:]
                    onChange(users)
                }
            }
        }
        
        // Handle presence leave
        channel.onPresenceLeave { [weak self] leftPresences in
            print("👋 User left room: \(roomId)")
            Task { @MainActor in
                // Get current state and notify
                if let channel = self?.presenceChannels[roomId] {
                    let currentState = channel.presenceState()
                    let users = self?.parsePresenceStates(currentState) ?? [:]
                    onChange(users)
                }
            }
        }
    }
    
    /// Parse presence states into user mood dictionary
    private func parsePresenceStates(_ states: [RealtimeChannelV2.PresenceState]) -> [String: RoomMood] {
        var users: [String: RoomMood] = [:]
        
        for state in states {
            // Try to decode the presence payload
            if let data = try? JSONSerialization.data(withJSONObject: state.payload),
               let decoded = try? JSONDecoder().decode([String: String].self, from: data),
               let userId = decoded["userId"],
               let moodString = decoded["mood"],
               let mood = RoomMood(rawValue: moodString) {
                users[userId] = mood
            }
        }
        
        return users
    }
    
    /// Update user mood in current room
    func updateMood(_ mood: RoomMood, in roomId: String) async {
        guard let channel = presenceChannels[roomId] else {
            print("❌ No presence channel found for room: \(roomId)")
            return
        }
        
        struct PresenceState: Codable {
            let userId: String
            let mood: String
            let updatedAt: String
        }
        
        let presenceState = PresenceState(
            userId: AuthService.shared.currentUser?.id.uuidString ?? "anonymous",
            mood: mood.rawValue,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        do {
            _ = try await channel.track(presenceState)
            print("✅ Updated mood to \(mood.rawValue) in room: \(roomId)")
        } catch {
            print("❌ Failed to update mood: \(error)")
        }
    }
    
    // MARK: - Room Events
    
    /// Listen to custom room events
    func listenToRoomEvents(in roomId: String, eventType: String, onEvent: @escaping ([String: Any]) -> Void) {
        guard let channel = activeRooms[roomId] else {
            print("❌ No active channel found for room: \(roomId)")
            return
        }
        
        channel.onBroadcast(event: eventType) { message in
            Task { @MainActor in
                if let payload = message.payload as? [String: Any] {
                    onEvent(payload)
                }
            }
        }
    }
    
    /// Send custom room event
    func sendRoomEvent(to roomId: String, eventType: String, payload: [String: Any]) async {
        guard let channel = activeRooms[roomId] else {
            print("❌ No active channel found for room: \(roomId)")
            return
        }
        
        do {
            try await channel.broadcast(event: eventType, message: payload)
            print("✅ Sent event '\(eventType)' to room: \(roomId)")
        } catch {
            print("❌ Failed to send event: \(error)")
        }
    }
}

// MARK: - Realtime Errors

enum RealtimeError: LocalizedError {
    case clientNotInitialized
    case connectionFailed
    case channelNotFound
    case subscriptionFailed
    
    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "Realtime client is not initialized"
        case .connectionFailed:
            return "Failed to connect to realtime service"
        case .channelNotFound:
            return "Realtime channel not found"
        case .subscriptionFailed:
            return "Failed to subscribe to channel"
        }
    }
}
