import Foundation
import Supabase
import Combine

@MainActor
class RealtimeService: ObservableObject {
    static let shared = RealtimeService()
    
    private let supabase = SupabaseManager.shared.client
    private var realtimeChannel: RealtimeChannelV2?
    private var connectionTask: Task<Void, Never>?
    private var heartbeatTimer: Timer?
    
    // Published properties for UI binding
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var participants: [Participant] = []
    @Published var messages: [ChatMessage] = []
    
    // Callback closures for real-time events
    var onConnectionStatusChanged: ((ConnectionStatus) -> Void)?
    var onParticipantsChanged: (([Participant]) -> Void)?
    var onMessageReceived: ((ChatMessage) -> Void)?
    var onPresenceUpdate: (([String: Any]) -> Void)?
    
    private var currentRoomId: String?
    private var isConnected = false
    
    private init() {
        setupConnectionMonitoring()
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Connection Management
    
    func connect() async {
        guard !isConnected else { return }
        
        connectionStatus = .connecting
        onConnectionStatusChanged?(.connecting)
        
        connectionTask = Task {
            do {
                // Connect to Supabase Realtime
                try await supabase.realtime.connect()
                
                await MainActor.run {
                    self.isConnected = true
                    self.connectionStatus = .connected
                    self.onConnectionStatusChanged?(.connected)
                }
                
                startHeartbeat()
                print("✅ Connected to Supabase Realtime")
                
            } catch {
                await MainActor.run {
                    self.connectionStatus = .error
                    self.onConnectionStatusChanged?(.error)
                }
                print("❌ Failed to connect to Realtime: \(error)")
                
                // Retry connection after delay
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                if !Task.isCancelled {
                    await connect()
                }
            }
        }
    }
    
    func disconnect() {
        connectionTask?.cancel()
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        Task {
            if let roomId = currentRoomId {
                await leaveRoom(roomId)
            }
            
            await supabase.realtime.disconnect()
            
            await MainActor.run {
                self.isConnected = false
                self.connectionStatus = .disconnected
                self.onConnectionStatusChanged?(.disconnected)
                self.participants.removeAll()
                self.messages.removeAll()
            }
        }
        
        print("🔌 Disconnected from Supabase Realtime")
    }
    
    // MARK: - Room Management
    
    func joinRoom(_ roomId: String) async {
        guard isConnected else {
            await connect()
            return
        }
        
        // Leave current room if any
        if let currentRoom = currentRoomId, currentRoom != roomId {
            await leaveRoom(currentRoom)
        }
        
        currentRoomId = roomId
        
        do {
            // Create or get existing channel for the room
            let channelName = "room:\(roomId)"
            realtimeChannel = await supabase.realtime.channel(channelName)
            
            // Subscribe to room events
            await setupRoomSubscriptions(roomId: roomId)
            
            // Subscribe to the channel
            try await realtimeChannel?.subscribe()
            
            // Join room presence
            await joinPresence(roomId: roomId)
            
            print("🏠 Joined room: \(roomId)")
            
        } catch {
            print("❌ Failed to join room \(roomId): \(error)")
        }
    }
    
    func leaveRoom(_ roomId: String) async {
        guard currentRoomId == roomId else { return }
        
        do {
            // Leave presence
            await leavePresence(roomId: roomId)
            
            // Unsubscribe from channel
            try await realtimeChannel?.unsubscribe()
            realtimeChannel = nil
            
            await MainActor.run {
                self.currentRoomId = nil
                self.participants.removeAll()
            }
            
            print("🚪 Left room: \(roomId)")
            
        } catch {
            print("❌ Failed to leave room \(roomId): \(error)")
        }
    }
    
    // MARK: - Presence Management
    
    private func joinPresence(roomId: String) async {
        guard let channel = realtimeChannel,
              let userId = supabase.auth.currentUser?.id.uuidString else { return }
        
        let presenceData: [String: Any] = [
            "user_id": userId,
            "room_id": roomId,
            "joined_at": ISO8601DateFormatter().string(from: Date()),
            "status": "online"
        ]
        
        do {
            try await channel.track(presenceData)
            print("👋 Joined presence for room: \(roomId)")
        } catch {
            print("❌ Failed to join presence: \(error)")
        }
    }
    
    private func leavePresence(roomId: String) async {
        guard let channel = realtimeChannel else { return }
        
        do {
            try await channel.untrack()
            print("👋 Left presence for room: \(roomId)")
        } catch {
            print("❌ Failed to leave presence: \(error)")
        }
    }
    
    // MARK: - Real-time Subscriptions
    
    private func setupRoomSubscriptions(roomId: String) async {
        guard let channel = realtimeChannel else { return }
        
        // Listen to presence changes
        await channel.onPresenceSync { [weak self] presenceState in
            Task { @MainActor in
                self?.handlePresenceSync(presenceState)
            }
        }
        
        await channel.onPresenceJoin { [weak self] presenceJoin in
            Task { @MainActor in
                self?.handlePresenceJoin(presenceJoin)
            }
        }
        
        await channel.onPresenceLeave { [weak self] presenceLeave in
            Task { @MainActor in
                self?.handlePresenceLeave(presenceLeave)
            }
        }
        
        // Listen to database changes for messages
        await channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "messages",
            filter: "room_id=eq.\(roomId)"
        ) { [weak self] change in
            Task { @MainActor in
                self?.handleMessageChange(change)
            }
        }
        
        // Listen to custom broadcast events
        await channel.onBroadcast("message") { [weak self] message in
            Task { @MainActor in
                self?.handleBroadcastMessage(message)
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handlePresenceSync(_ presenceState: [String: [PresenceV2]]) {
        let newParticipants = extractParticipants(from: presenceState)
        participants = newParticipants
        onParticipantsChanged?(newParticipants)
        onPresenceUpdate?(presenceState as [String: Any])
    }
    
    private func handlePresenceJoin(_ presenceJoin: PresenceJoinV2) {
        print("👤 User joined: \(presenceJoin)")
        // Update participants list
        let newParticipants = extractParticipants(from: presenceJoin.currentPresences)
        participants = newParticipants
        onParticipantsChanged?(newParticipants)
    }
    
    private func handlePresenceLeave(_ presenceLeave: PresenceLeaveV2) {
        print("👤 User left: \(presenceLeave)")
        // Update participants list
        let newParticipants = extractParticipants(from: presenceLeave.currentPresences)
        participants = newParticipants
        onParticipantsChanged?(newParticipants)
    }
    
    private func handleMessageChange(_ change: AnyAction) {
        print("💬 Message change: \(change)")
        
        switch change {
        case .insert(let record):
            if let messageData = record.record as? [String: Any],
               let message = try? ChatMessage.from(dictionary: messageData) {
                messages.append(message)
                onMessageReceived?(message)
            }
        case .update(let record):
            // Handle message updates if needed
            break
        case .delete(let record):
            // Handle message deletions if needed
            break
        }
    }
    
    private func handleBroadcastMessage(_ message: JSONObject) {
        print("📡 Broadcast message: \(message)")
        // Handle custom broadcast messages
    }
    
    // MARK: - Message Broadcasting
    
    func sendMessage(_ content: String, roomId: String) async {
        guard let channel = realtimeChannel,
              let userId = supabase.auth.currentUser?.id.uuidString else { return }
        
        let messageData: [String: Any] = [
            "room_id": roomId,
            "user_id": userId,
            "content": content,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            try await channel.send(
                type: .broadcast,
                event: "message",
                payload: messageData
            )
            print("📤 Sent message: \(content)")
        } catch {
            print("❌ Failed to send message: \(error)")
        }
    }
    
    func sendCustomEvent(_ event: String, payload: [String: Any]) async {
        guard let channel = realtimeChannel else { return }
        
        do {
            try await channel.send(
                type: .broadcast,
                event: event,
                payload: payload
            )
            print("📤 Sent custom event: \(event)")
        } catch {
            print("❌ Failed to send custom event: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    private func extractParticipants(from presenceState: [String: [PresenceV2]]) -> [Participant] {
        var participants: [Participant] = []
        
        for (_, presences) in presenceState {
            for presence in presences {
                if let userId = presence.payload["user_id"] as? String {
                    let participant = Participant(
                        id: userId,
                        name: "User \(userId.prefix(8))", // Simplified name
                        isMuted: false,
                        isVideoEnabled: true
                    )
                    participants.append(participant)
                }
            }
        }
        
        return participants
    }
    
    private func setupConnectionMonitoring() {
        // Monitor network connectivity and reconnect if needed
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                if self?.connectionStatus == .disconnected {
                    await self?.connect()
                }
            }
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.sendHeartbeat()
            }
        }
    }
    
    private func sendHeartbeat() async {
        guard let roomId = currentRoomId else { return }
        
        await sendCustomEvent("heartbeat", payload: [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "room_id": roomId
        ])
    }
}

// MARK: - Extensions

extension ChatMessage {
    static func from(dictionary: [String: Any]) throws -> ChatMessage {
        guard let id = dictionary["id"] as? String,
              let roomId = dictionary["room_id"] as? String,
              let userId = dictionary["user_id"] as? String,
              let content = dictionary["content"] as? String,
              let createdAtString = dictionary["created_at"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            throw NSError(domain: "ChatMessage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid message data"])
        }
        
        return ChatMessage(
            id: id,
            roomId: roomId,
            userId: userId,
            content: content,
            createdAt: createdAt
        )
    }
}

// MARK: - Connection Status

enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
    case error
    
    var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Connection Error"
        }
    }
    
    var color: Color {
        switch self {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
}

// MARK: - Supporting Types

struct PresenceV2 {
    let payload: [String: Any]
}

struct PresenceJoinV2 {
    let currentPresences: [String: [PresenceV2]]
}

struct PresenceLeaveV2 {
    let currentPresences: [String: [PresenceV2]]
}

enum AnyAction {
    case insert(record: (record: Any, schema: String, table: String))
    case update(record: (record: Any, old_record: Any, schema: String, table: String))
    case delete(record: (old_record: Any, schema: String, table: String))
}

typealias JSONObject = [String: Any]

// MARK: - RealtimeChannelV2 Mock

class RealtimeChannelV2 {
    private let channelName: String
    
    init(channelName: String) {
        self.channelName = channelName
    }
    
    func subscribe() async throws {
        // Mock implementation
        print("📡 Subscribed to channel: \(channelName)")
    }
    
    func unsubscribe() async throws {
        // Mock implementation
        print("📡 Unsubscribed from channel: \(channelName)")
    }
    
    func track(_ payload: [String: Any]) async throws {
        // Mock implementation
        print("👋 Tracking presence: \(payload)")
    }
    
    func untrack() async throws {
        // Mock implementation
        print("👋 Stopped tracking presence")
    }
    
    func send(type: MessageType, event: String, payload: [String: Any]) async throws {
        // Mock implementation
        print("📤 Sent \(type) event '\(event)': \(payload)")
    }
    
    func onPresenceSync(_ callback: @escaping ([String: [PresenceV2]]) -> Void) async {
        // Mock implementation
    }
    
    func onPresenceJoin(_ callback: @escaping (PresenceJoinV2) -> Void) async {
        // Mock implementation
    }
    
    func onPresenceLeave(_ callback: @escaping (PresenceLeaveV2) -> Void) async {
        // Mock implementation
    }
    
    func onPostgresChange<T>(
        _ action: T.Type,
        schema: String,
        table: String,
        filter: String,
        callback: @escaping (AnyAction) -> Void
    ) async {
        // Mock implementation
    }
    
    func onBroadcast(_ event: String, callback: @escaping (JSONObject) -> Void) async {
        // Mock implementation
    }
}

enum MessageType {
    case broadcast
    case presence
}

// MARK: - Realtime Mock Extension

extension SupabaseClient {
    var realtime: RealtimeMock {
        return RealtimeMock()
    }
}

class RealtimeMock {
    func connect() async throws {
        // Mock implementation
        print("🔌 Connected to Realtime")
    }
    
    func disconnect() async {
        // Mock implementation
        print("🔌 Disconnected from Realtime")
    }
    
    func channel(_ name: String) async -> RealtimeChannelV2 {
        return RealtimeChannelV2(channelName: name)
    }
}
