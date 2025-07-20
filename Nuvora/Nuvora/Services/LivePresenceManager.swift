import Foundation
import Supabase
import Combine

/// LivePresenceManager keeps track of users who are currently present in a room,
/// manages mood updates, and exposes real-time callbacks for the UI.
/// Built for Supabase Swift SDK 2.5.1+ with enhanced error handling and state management.
final class LivePresenceManager: ObservableObject {
    static let shared = LivePresenceManager()
    
    // MARK: - Published Properties
    @Published var currentRoomID: String?
    @Published var currentMood: RoomMood?
    @Published var liveUsers: [String: RoomMood] = [:]
    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    
    // MARK: - Private Properties
    private var realtimeService: RealtimeService {
        RealtimeService.shared
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var onLiveUsersChange: (([String: RoomMood]) -> Void)?
    
    private init() {
        setupRealtimeServiceListener()
    }
    
    private func setupRealtimeServiceListener() {
        // Monitor realtime service connection
        realtimeService.$isConnected
            .sink { [weak self] isConnected in
                self?.isConnected = isConnected
            }
            .store(in: &cancellables)
        
        realtimeService.$connectionError
            .sink { [weak self] error in
                self?.connectionError = error
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Join a room with presence tracking
    func join(roomID: String, mood: RoomMood) async {
        // Leave current room if any
        await leaveCurrentRoomIfNeeded()
        
        do {
            let _ = try await realtimeService.joinRoom(roomID, userMood: mood)
            
            await MainActor.run {
                self.currentRoomID = roomID
                self.currentMood = mood
            }
            
            // Setup presence listening
            setupPresenceListening(for: roomID)
            
            print("✅ LivePresenceManager: Joined room \(roomID) with mood \(mood.rawValue)")
            
        } catch {
            await MainActor.run {
                self.connectionError = "Failed to join room: \(error.localizedDescription)"
            }
            print("❌ LivePresenceManager: Failed to join room \(roomID): \(error)")
        }
    }
    
    /// Leave the current room
    func leave(roomID: String? = nil) async {
        let targetRoomID = roomID ?? currentRoomID
        
        guard let roomToLeave = targetRoomID else {
            print("⚠️ LivePresenceManager: No room to leave")
            return
        }
        
        await realtimeService.leaveRoom(roomToLeave)
        
        await MainActor.run {
            if self.currentRoomID == roomToLeave {
                self.currentRoomID = nil
                self.currentMood = nil
                self.liveUsers.removeAll()
            }
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
        
        await MainActor.run {
            self.currentMood = mood
        }
        
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
    
    /// Check if user is currently in a room
    var isInRoom: Bool {
        return currentRoomID != nil
    }
    
    // MARK: - Private Methods
    
    private func setupPresenceListening(for roomID: String) {
        realtimeService.listenToPresence(in: roomID) { [weak self] users in
            DispatchQueue.main.async {
                self?.liveUsers = users
                self?.onLiveUsersChange?(users)
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
}