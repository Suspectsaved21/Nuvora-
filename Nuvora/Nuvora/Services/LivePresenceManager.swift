import Foundation
import Supabase
import Combine

/// LivePresenceManager keeps track of users who are currently present in a room,
/// manages mood updates, and exposes real-time callbacks for the UI.
/// Built for Supabase Swift SDK 2.5.1+ with enhanced error handling and state management.
@MainActor
final class LivePresenceManager: ObservableObject {
    static let shared = LivePresenceManager()
    
    // MARK: - Published Properties
    @Published var currentRoomID: String?
    @Published var currentMood: RoomMood?
    @Published var liveUsers: [String: RoomMood] = [:]
    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    @Published var presenceCount: Int = 0
    @Published var isJoining: Bool = false
    @Published var isLeaving: Bool = false
    
    // MARK: - Private Properties
    private var realtimeService: RealtimeService {
        RealtimeService.shared
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var onLiveUsersChange: (([String: RoomMood]) -> Void)?
    private var presenceUpdateTimer: Timer?
    
    private init() {
        setupRealtimeServiceListener()
        setupPresenceUpdateTimer()
    }
    
    deinit {
        presenceUpdateTimer?.invalidate()
        cancellables.removeAll()
    }
    
    private func setupRealtimeServiceListener() {
        // Monitor realtime service connection
        realtimeService.$isConnected
            .sink { [weak self] isConnected in
                Task { @MainActor in
                    self?.isConnected = isConnected
                    if !isConnected {
                        self?.handleConnectionLoss()
                    }
                }
            }
            .store(in: &cancellables)
        
        realtimeService.$connectionError
            .sink { [weak self] error in
                Task { @MainActor in
                    self?.connectionError = error
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupPresenceUpdateTimer() {
        // Send periodic presence updates to maintain connection
        presenceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.sendHeartbeat()
            }
        }
    }
    
    private func handleConnectionLoss() {
        // Clear presence data when connection is lost
        liveUsers.removeAll()
        presenceCount = 0
        connectionError = "Connection lost. Attempting to reconnect..."
        
        // Attempt to rejoin if we were in a room
        if let roomID = currentRoomID, let mood = currentMood {
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                await rejoinRoom(roomID: roomID, mood: mood)
            }
        }
    }
    
    private func rejoinRoom(roomID: String, mood: RoomMood) async {
        print("🔄 Attempting to rejoin room \(roomID) after connection loss")
        await join(roomID: roomID, mood: mood)
    }
    
    private func sendHeartbeat() async {
        guard let roomID = currentRoomID, let mood = currentMood, isConnected else { return }
        
        // Update presence to maintain active status
        await realtimeService.updateMood(mood, in: roomID)
    }
    
    // MARK: - Public Methods
    
    /// Join a room with presence tracking
    func join(roomID: String, mood: RoomMood) async {
        guard !isJoining else {
            print("⚠️ Already joining a room, please wait...")
            return
        }
        
        isJoining = true
        defer { isJoining = false }
        
        // Leave current room if any
        await leaveCurrentRoomIfNeeded()
        
        do {
            let _ = try await realtimeService.joinRoom(roomID, userMood: mood)
            
            currentRoomID = roomID
            currentMood = mood
            connectionError = nil
            
            // Setup presence listening
            setupPresenceListening(for: roomID)
            
            print("✅ LivePresenceManager: Joined room \(roomID) with mood \(mood.rawValue)")
            
        } catch {
            connectionError = "Failed to join room: \(error.localizedDescription)"
            print("❌ LivePresenceManager: Failed to join room \(roomID): \(error)")
        }
    }
    
    /// Leave the current room
    func leave(roomID: String? = nil) async {
        guard !isLeaving else {
            print("⚠️ Already leaving a room, please wait...")
            return
        }
        
        isLeaving = true
        defer { isLeaving = false }
        
        let targetRoomID = roomID ?? currentRoomID
        
        guard let roomToLeave = targetRoomID else {
            print("⚠️ LivePresenceManager: No room to leave")
            return
        }
        
        await realtimeService.leaveRoom(roomToLeave)
        
        if currentRoomID == roomToLeave {
            currentRoomID = nil
            currentMood = nil
            liveUsers.removeAll()
            presenceCount = 0
            onLiveUsersChange = nil
        }
        
        print("✅ LivePresenceManager: Left room \(roomToLeave)")
    }
    
    /// Update mood in current room
    func updateMood(_ mood: RoomMood) async {
        guard let roomID = currentRoomID else {
            print("❌ LivePresenceManager: No current room to update mood")
            return
        }
        
        await realtimeService.updateMood(mood, in: roomID)
        currentMood = mood
        
        print("✅ LivePresenceManager: Updated mood to \(mood.rawValue)")
    }
    
    /// Subscribe to live user changes with callback
    func listenToLiveUsers(onChange: @escaping ([String: RoomMood]) -> Void) {
        self.onLiveUsersChange = onChange
        
        // If already in a room, start listening immediately
        if let roomID = currentRoomID {
            setupPresenceListening(for: roomID)
        }
    }
    
    /// Get current live users in the room
    func getCurrentLiveUsers() -> [String: RoomMood] {
        return liveUsers
    }
    
    /// Get current presence count
    func getPresenceCount() -> Int {
        return presenceCount
    }
    
    /// Check if user is currently in a room
    var isInRoom: Bool {
        return currentRoomID != nil
    }
    
    /// Check if a specific user is present in the room
    func isUserPresent(_ userID: String) -> Bool {
        return liveUsers.keys.contains(userID)
    }
    
    /// Get mood of a specific user
    func getUserMood(_ userID: String) -> RoomMood? {
        return liveUsers[userID]
    }
    
    /// Get users by mood
    func getUsersByMood(_ mood: RoomMood) -> [String] {
        return liveUsers.compactMap { key, value in
            value == mood ? key : nil
        }
    }
    
    /// Force refresh presence data
    func refreshPresence() async {
        guard let roomID = currentRoomID else { return }
        setupPresenceListening(for: roomID)
    }
    
    // MARK: - Private Methods
    
    private func setupPresenceListening(for roomID: String) {
        realtimeService.listenToPresence(in: roomID) { [weak self] users in
            Task { @MainActor in
                self?.liveUsers = users
                self?.presenceCount = users.count
                self?.onLiveUsersChange?(users)
                
                // Clear connection error if we successfully receive presence data
                if self?.connectionError != nil {
                    self?.connectionError = nil
                }
            }
        }
    }
    
    private func leaveCurrentRoomIfNeeded() async {
        if let currentRoom = currentRoomID {
            await leave(roomID: currentRoom)
        }
    }
    
    // MARK: - Room Events
    
    /// Send a custom event to the current room
    func sendRoomEvent(eventType: String, payload: [String: Any]) async {
        guard let roomID = currentRoomID else {
            print("❌ LivePresenceManager: No current room to send event")
            return
        }
        
        await realtimeService.sendRoomEvent(to: roomID, eventType: eventType, payload: payload)
    }
    
    /// Listen to custom room events
    func listenToRoomEvents(eventType: String, onEvent: @escaping ([String: Any]) -> Void) {
        guard let roomID = currentRoomID else {
            print("❌ LivePresenceManager: No current room to listen to events")
            return
        }
        
        realtimeService.listenToRoomEvents(in: roomID, eventType: eventType, onEvent: onEvent)
    }
    
    // MARK: - Advanced Features
    
    /// Send a mood reaction to other users in the room
    func sendMoodReaction(_ reaction: String) async {
        guard let userID = AuthService.shared.currentUser?.id else { return }
        
        let payload: [String: Any] = [
            "type": "mood_reaction",
            "user_id": userID,
            "reaction": reaction,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        await sendRoomEvent(eventType: "mood_reaction", payload: payload)
    }
    
    /// Send a typing indicator
    func sendTypingIndicator(isTyping: Bool) async {
        guard let userID = AuthService.shared.currentUser?.id else { return }
        
        let payload: [String: Any] = [
            "type": "typing_indicator",
            "user_id": userID,
            "is_typing": isTyping,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        await sendRoomEvent(eventType: "typing_indicator", payload: payload)
    }
    
    /// Listen to mood reactions
    func listenToMoodReactions(onReaction: @escaping (String, String) -> Void) {
        listenToRoomEvents(eventType: "mood_reaction") { payload in
            if let userID = payload["user_id"] as? String,
               let reaction = payload["reaction"] as? String {
                onReaction(userID, reaction)
            }
        }
    }
    
    /// Listen to typing indicators
    func listenToTypingIndicators(onTyping: @escaping (String, Bool) -> Void) {
        listenToRoomEvents(eventType: "typing_indicator") { payload in
            if let userID = payload["user_id"] as? String,
               let isTyping = payload["is_typing"] as? Bool {
                onTyping(userID, isTyping)
            }
        }
    }
    
    // MARK: - Connection Management
    
    /// Manually reconnect to the realtime service
    func reconnect() async {
        realtimeService.connect()
        
        // If we were in a room, rejoin it
        if let roomID = currentRoomID, let mood = currentMood {
            await rejoinRoom(roomID: roomID, mood: mood)
        }
    }
    
    /// Disconnect from the realtime service
    func disconnect() async {
        await leave()
        realtimeService.disconnect()
    }
    
    /// Get connection status information
    func getConnectionStatus() -> (isConnected: Bool, error: String?, roomID: String?) {
        return (isConnected, connectionError, currentRoomID)
    }
}