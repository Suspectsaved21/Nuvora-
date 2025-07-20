import Foundation
import Supabase
import Combine

/// Comprehensive real-time service for presence and room management
class RealtimeService: ObservableObject {
    static let shared = RealtimeService()
    
    @Published var isConnected = false
    @Published var connectionError: String?
    @Published var activeRooms: [String: RealtimeChannel] = [:]
    
    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }
    
    private var presenceChannels: [String: RealtimeChannel] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupConnectionListener()
    }
    
    private func setupConnectionListener() {
        // Monitor Supabase manager initialization
        SupabaseManager.shared.$isInitialized
            .sink { [weak self] isInitialized in
                if isInitialized {
                    self?.connect()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard let client = client else {
            print("❌ Cannot connect: Supabase client not initialized")
            return
        }
        
        Task {
            do {
                try await client.realtime.connect()
                await MainActor.run {
                    self.isConnected = true
                    self.connectionError = nil
                }
                print("✅ Realtime connected")
            } catch {
                await MainActor.run {
                    self.isConnected = false
                    self.connectionError = error.localizedDescription
                }
                print("❌ Realtime connection failed: \(error)")
            }
        }
    }
    
    func disconnect() {
        guard let client = client else { return }
        
        Task {
            await client.realtime.disconnect()
            await MainActor.run {
                self.isConnected = false
                self.activeRooms.removeAll()
                self.presenceChannels.removeAll()
            }
            print("👋 Realtime disconnected")
        }
    }
    
    // MARK: - Room Management
    
    /// Join a room with presence tracking
    func joinRoom(_ roomId: String, userMood: RoomMood) async throws -> RealtimeChannel {
        guard let client = client else {
            throw RealtimeError.clientNotInitialized
        }
        
        // Leave existing room if any
        await leaveCurrentRooms()
        
        let channelName = "room:\(roomId)"
        let channel = client.realtime.channel(channelName)
        
        // Setup presence tracking
        let presenceState: [String: Any] = [
            "user_id": AuthService.shared.currentUser?.id ?? "anonymous",
            "mood": userMood.rawValue,
            "joined_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Subscribe to channel
        await channel.subscribe()
        
        // Track presence
        await channel.track(presenceState)
        
        // Store channel reference
        await MainActor.run {
            self.activeRooms[roomId] = channel
            self.presenceChannels[roomId] = channel
        }
        
        print("✅ Joined room: \(roomId) with mood: \(userMood.rawValue)")
        return channel
    }
    
    /// Leave a specific room
    func leaveRoom(_ roomId: String) async {
        guard let channel = activeRooms[roomId] else { return }
        
        await channel.untrack()
        await channel.unsubscribe()
        
        await MainActor.run {
            self.activeRooms.removeValue(forKey: roomId)
            self.presenceChannels.removeValue(forKey: roomId)
        }
        
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
        
        channel.onPresenceSync { state in
            var users: [String: RoomMood] = [:]
            
            for (userId, presences) in state {
                if let presence = presences.first,
                   let moodString = presence["mood"]?.stringValue,
                   let mood = RoomMood(rawValue: moodString) {
                    users[userId] = mood
                }
            }
            
            DispatchQueue.main.async {
                onChange(users)
            }
        }
        
        channel.onPresenceJoin { _, newPresences in
            print("👋 User joined room: \(roomId)")
            // Trigger sync to get updated state
            let currentState = channel.presenceState()
            var users: [String: RoomMood] = [:]
            
            for (userId, presences) in currentState {
                if let presence = presences.first,
                   let moodString = presence["mood"]?.stringValue,
                   let mood = RoomMood(rawValue: moodString) {
                    users[userId] = mood
                }
            }
            
            DispatchQueue.main.async {
                onChange(users)
            }
        }
        
        channel.onPresenceLeave { _, leftPresences in
            print("👋 User left room: \(roomId)")
            // Trigger sync to get updated state
            let currentState = channel.presenceState()
            var users: [String: RoomMood] = [:]
            
            for (userId, presences) in currentState {
                if let presence = presences.first,
                   let moodString = presence["mood"]?.stringValue,
                   let mood = RoomMood(rawValue: moodString) {
                    users[userId] = mood
                }
            }
            
            DispatchQueue.main.async {
                onChange(users)
            }
        }
    }
    
    /// Update user mood in current room
    func updateMood(_ mood: RoomMood, in roomId: String) async {
        guard let channel = presenceChannels[roomId] else {
            print("❌ No presence channel found for room: \(roomId)")
            return
        }
        
        let presenceState: [String: Any] = [
            "user_id": AuthService.shared.currentUser?.id ?? "anonymous",
            "mood": mood.rawValue,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        await channel.track(presenceState)
        print("✅ Updated mood to \(mood.rawValue) in room: \(roomId)")
    }
    
    // MARK: - Room Events
    
    /// Listen to custom room events
    func listenToRoomEvents(in roomId: String, eventType: String, onEvent: @escaping ([String: Any]) -> Void) {
        guard let channel = activeRooms[roomId] else {
            print("❌ No active channel found for room: \(roomId)")
            return
        }
        
        channel.on(eventType) { message in
            if let payload = message.payload as? [String: Any] {
                DispatchQueue.main.async {
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
        
        await channel.send(eventType, payload: payload)
        print("✅ Sent event '\(eventType)' to room: \(roomId)")
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