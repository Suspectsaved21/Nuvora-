import Foundation
import SwiftUI
import Supabase
import Combine

/// Enhanced RoomViewModel using the new RoomService with comprehensive functionality
@MainActor
class RoomViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var rooms: [Room] = []
    @Published var searchTerm: String = ""
    @Published var selectedMoodFilter: RoomMood?
    @Published var showOnlyAvailable: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var latestEventMessage: String?
    @Published var shouldTriggerConfetti = false
    @Published var currentRoom: Room?
    
    // Enhanced presence properties
    @Published var liveUsers: [String: RoomMood] = [:]
    @Published var presenceCount: Int = 0
    @Published var isPresenceConnected: Bool = false
    @Published var presenceError: String?
    @Published var typingUsers: Set<String> = []
    @Published var recentMoodReactions: [(userID: String, reaction: String, timestamp: Date)] = []
    
    // MARK: - Private Properties
    private var roomService: RoomService {
        RoomService.shared
    }
    
    private var livePresenceManager: LivePresenceManager {
        LivePresenceManager.shared
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var reactionCleanupTimer: Timer?
    
    // MARK: - Computed Properties
    var filteredRooms: [Room] {
        var filtered = rooms
        
        // Apply search filter
        if !searchTerm.isEmpty {
            filtered = filtered.filter { room in
                room.name.lowercased().contains(searchTerm.lowercased()) ||
                room.description?.lowercased().contains(searchTerm.lowercased()) == true
            }
        }
        
        // Apply mood filter
        if let selectedMood = selectedMoodFilter {
            filtered = filtered.filter { $0.mood == selectedMood }
        }
        
        // Apply availability filter
        if showOnlyAvailable {
            filtered = filtered.filter { $0.hasSpace }
        }
        
        return filtered
    }
    
    var availableRoomsCount: Int {
        return rooms.filter { $0.hasSpace }.count
    }
    
    var totalParticipants: Int {
        return rooms.reduce(0) { $0 + $1.participants }
    }
    
    var isInRoom: Bool {
        return currentRoom != nil
    }
    
    var connectionStatus: String {
        if isPresenceConnected {
            return "Connected"
        } else if let error = presenceError {
            return "Error: \(error)"
        } else {
            return "Disconnected"
        }
    }
    
    // MARK: - Initialization
    init() {
        setupRoomServiceBindings()
        setupLivePresenceBindings()
        setupReactionCleanup()
        
        Task {
            await fetchRooms()
        }
    }
    
    deinit {
        reactionCleanupTimer?.invalidate()
        cancellables.removeAll()
    }
    
    private func setupRoomServiceBindings() {
        // Bind room service properties to view model
        roomService.$rooms
            .receive(on: DispatchQueue.main)
            .assign(to: \.rooms, on: self)
            .store(in: &cancellables)
        
        roomService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        roomService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    private func setupLivePresenceBindings() {
        // Monitor current room from presence manager
        livePresenceManager.$currentRoomID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomID in
                if let roomID = roomID {
                    self?.currentRoom = self?.rooms.first { $0.id == roomID }
                } else {
                    self?.currentRoom = nil
                }
            }
            .store(in: &cancellables)
        
        // Monitor live users
        livePresenceManager.$liveUsers
            .receive(on: DispatchQueue.main)
            .assign(to: \.liveUsers, on: self)
            .store(in: &cancellables)
        
        // Monitor presence count
        livePresenceManager.$presenceCount
            .receive(on: DispatchQueue.main)
            .assign(to: \.presenceCount, on: self)
            .store(in: &cancellables)
        
        // Monitor connection status
        livePresenceManager.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPresenceConnected, on: self)
            .store(in: &cancellables)
        
        // Monitor presence errors
        livePresenceManager.$connectionError
            .receive(on: DispatchQueue.main)
            .assign(to: \.presenceError, on: self)
            .store(in: &cancellables)
        
        // Setup presence event listeners
        setupPresenceEventListeners()
    }
    
    private func setupPresenceEventListeners() {
        // Listen to mood reactions
        livePresenceManager.listenToMoodReactions { [weak self] userID, reaction in
            Task { @MainActor in
                self?.handleMoodReaction(userID: userID, reaction: reaction)
            }
        }
        
        // Listen to typing indicators
        livePresenceManager.listenToTypingIndicators { [weak self] userID, isTyping in
            Task { @MainActor in
                self?.handleTypingIndicator(userID: userID, isTyping: isTyping)
            }
        }
    }
    
    private func setupReactionCleanup() {
        // Clean up old reactions every 10 seconds
        reactionCleanupTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupOldReactions()
            }
        }
    }
    
    private func handleMoodReaction(userID: String, reaction: String) {
        let reactionData = (userID: userID, reaction: reaction, timestamp: Date())
        recentMoodReactions.append(reactionData)
        
        // Limit to last 20 reactions
        if recentMoodReactions.count > 20 {
            recentMoodReactions.removeFirst()
        }
        
        // Show temporary message
        latestEventMessage = "\(reaction) from user"
        
        // Clear message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.latestEventMessage == "\(reaction) from user" {
                self.latestEventMessage = nil
            }
        }
    }
    
    private func handleTypingIndicator(userID: String, isTyping: Bool) {
        if isTyping {
            typingUsers.insert(userID)
        } else {
            typingUsers.remove(userID)
        }
    }
    
    private func cleanupOldReactions() {
        let cutoffTime = Date().addingTimeInterval(-30) // Remove reactions older than 30 seconds
        recentMoodReactions.removeAll { $0.timestamp < cutoffTime }
    }
    
    // MARK: - Room Management
    
    /// Fetch all rooms
    func fetchRooms() async {
        await roomService.fetchRooms()
    }
    
    /// Create a new room
    func createRoom(name: String, maxParticipants: Int, isPrivate: Bool, mood: RoomMood, description: String? = nil) async {
        let newRoom = Room(
            name: name,
            participants: 0, // Start with 0, will increment when creator joins
            maxParticipants: maxParticipants,
            isPrivate: isPrivate,
            mood: mood,
            createdBy: AuthService.shared.currentUser?.id,
            description: description
        )
        
        do {
            let createdRoom = try await roomService.createRoom(newRoom)
            
            latestEventMessage = "🚀 Room '\(name)' created!"
            shouldTriggerConfetti = true
            
            // Auto-join the created room
            await joinRoom(roomID: createdRoom.id, mood: mood)
            
            // Clear success message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.latestEventMessage = nil
                self.shouldTriggerConfetti = false
            }
            
        } catch {
            errorMessage = "Failed to create room: \(error.localizedDescription)"
        }
    }
    
    /// Join a room with presence tracking
    func joinRoom(roomID: String, mood: RoomMood) async {
        guard let room = rooms.first(where: { $0.id == roomID }) else {
            errorMessage = "Room not found"
            return
        }
        
        guard room.hasSpace else {
            errorMessage = "Room is full"
            return
        }
        
        do {
            // Update room participant count
            let _ = try await roomService.joinRoom(roomID)
            
            // Join with live presence
            await livePresenceManager.join(roomID: roomID, mood: mood)
            
            latestEventMessage = "🎉 Joined '\(room.name)'!"
            shouldTriggerConfetti = true
            currentRoom = room
            
            // Clear success message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.latestEventMessage = nil
                self.shouldTriggerConfetti = false
            }
            
        } catch {
            errorMessage = "Failed to join room: \(error.localizedDescription)"
        }
    }
    
    /// Leave the current room
    func leaveCurrentRoom() async {
        guard let currentRoom = currentRoom else { return }
        
        do {
            // Update room participant count
            let _ = try await roomService.leaveRoom(currentRoom.id)
            
            // Leave live presence
            await livePresenceManager.leave()
            
            latestEventMessage = "👋 Left '\(currentRoom.name)'"
            self.currentRoom = nil
            
            // Clear typing indicators and reactions
            typingUsers.removeAll()
            recentMoodReactions.removeAll()
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.latestEventMessage = nil
            }
            
        } catch {
            errorMessage = "Failed to leave room: \(error.localizedDescription)"
        }
    }
    
    /// Update mood in current room
    func updateMood(_ mood: RoomMood) async {
        guard currentRoom != nil else { return }
        
        await livePresenceManager.updateMood(mood)
        
        latestEventMessage = "🎭 Mood updated to \(mood.emoji)"
        
        // Clear message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.latestEventMessage = nil
        }
    }
    
    /// Delete a room (only if user is the creator)
    func deleteRoom(_ roomID: String) async {
        guard let room = rooms.first(where: { $0.id == roomID }),
              room.createdBy == AuthService.shared.currentUser?.id else {
            errorMessage = "You can only delete rooms you created"
            return
        }
        
        do {
            try await roomService.deleteRoom(roomID)
            
            latestEventMessage = "🗑️ Room '\(room.name)' deleted"
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.latestEventMessage = nil
            }
            
        } catch {
            errorMessage = "Failed to delete room: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Search and Filter
    
    /// Search rooms by query
    func searchRooms() async {
        if searchTerm.isEmpty {
            await fetchRooms()
        } else {
            await roomService.searchRooms(query: searchTerm)
        }
    }
    
    /// Filter rooms by mood
    func filterByMood(_ mood: RoomMood?) async {
        selectedMoodFilter = mood
        
        if let mood = mood {
            await roomService.filterRoomsByMood(mood)
        } else {
            await fetchRooms()
        }
    }
    
    /// Show only available rooms
    func toggleAvailableFilter() async {
        showOnlyAvailable.toggle()
        
        if showOnlyAvailable {
            await roomService.getAvailableRooms()
        } else {
            await fetchRooms()
        }
    }
    
    /// Clear all filters
    func clearFilters() async {
        searchTerm = ""
        selectedMoodFilter = nil
        showOnlyAvailable = false
        await fetchRooms()
    }
    
    // MARK: - Presence Features
    
    /// Send a mood reaction
    func sendMoodReaction(_ reaction: String) async {
        await livePresenceManager.sendMoodReaction(reaction)
    }
    
    /// Send typing indicator
    func setTyping(_ isTyping: Bool) async {
        await livePresenceManager.sendTypingIndicator(isTyping: isTyping)
    }
    
    /// Get users by mood in current room
    func getUsersByMood(_ mood: RoomMood) -> [String] {
        return livePresenceManager.getUsersByMood(mood)
    }
    
    /// Check if a user is present
    func isUserPresent(_ userID: String) -> Bool {
        return livePresenceManager.isUserPresent(userID)
    }
    
    /// Get user's current mood
    func getUserMood(_ userID: String) -> RoomMood? {
        return livePresenceManager.getUserMood(userID)
    }
    
    /// Refresh presence data
    func refreshPresence() async {
        await livePresenceManager.refreshPresence()
    }
    
    /// Reconnect to presence service
    func reconnectPresence() async {
        await livePresenceManager.reconnect()
    }
    
    // MARK: - Utility Methods
    
    /// Refresh rooms data
    func refresh() async {
        await roomService.refresh()
        if isInRoom {
            await refreshPresence()
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
        presenceError = nil
        roomService.clearError()
    }
    
    /// Check if user can delete a room
    func canDeleteRoom(_ room: Room) -> Bool {
        return room.createdBy == AuthService.shared.currentUser?.id
    }
    
    /// Get live users in current room
    func getLiveUsers() -> [String: RoomMood] {
        return livePresenceManager.getCurrentLiveUsers()
    }
    
    /// Get typing status message
    func getTypingStatusMessage() -> String? {
        let typingCount = typingUsers.count
        if typingCount == 0 {
            return nil
        } else if typingCount == 1 {
            return "1 user is typing..."
        } else {
            return "\(typingCount) users are typing..."
        }
    }
    
    /// Get recent reactions for display
    func getRecentReactions() -> [(userID: String, reaction: String, timestamp: Date)] {
        return Array(recentMoodReactions.suffix(5)) // Show last 5 reactions
    }
}