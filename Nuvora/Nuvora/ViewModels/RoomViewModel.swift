import Foundation
import SwiftUI
import Supabase
import Combine

/// Enhanced RoomViewModel using the new RoomService with comprehensive functionality
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
    
    // MARK: - Private Properties
    private var roomService: RoomService {
        RoomService.shared
    }
    
    private var livePresenceManager: LivePresenceManager {
        LivePresenceManager.shared
    }
    
    private var cancellables = Set<AnyCancellable>()
    
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
    
    // MARK: - Initialization
    init() {
        setupRoomServiceBindings()
        setupLivePresenceBindings()
        
        Task {
            await fetchRooms()
        }
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
            
            await MainActor.run {
                self.latestEventMessage = "🚀 Room '\(name)' created!"
                self.shouldTriggerConfetti = true
            }
            
            // Auto-join the created room
            await joinRoom(roomID: createdRoom.id, mood: mood)
            
            // Clear success message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.latestEventMessage = nil
                self.shouldTriggerConfetti = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create room: \(error.localizedDescription)"
            }
        }
    }
    
    /// Join a room with presence tracking
    func joinRoom(roomID: String, mood: RoomMood) async {
        guard let room = rooms.first(where: { $0.id == roomID }) else {
            await MainActor.run {
                self.errorMessage = "Room not found"
            }
            return
        }
        
        guard room.hasSpace else {
            await MainActor.run {
                self.errorMessage = "Room is full"
            }
            return
        }
        
        do {
            // Update room participant count
            let _ = try await roomService.joinRoom(roomID)
            
            // Join with live presence
            await livePresenceManager.join(roomID: roomID, mood: mood)
            
            await MainActor.run {
                self.latestEventMessage = "🎉 Joined '\(room.name)'!"
                self.shouldTriggerConfetti = true
                self.currentRoom = room
            }
            
            // Clear success message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.latestEventMessage = nil
                self.shouldTriggerConfetti = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to join room: \(error.localizedDescription)"
            }
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
            
            await MainActor.run {
                self.latestEventMessage = "👋 Left '\(currentRoom.name)'"
                self.currentRoom = nil
            }
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.latestEventMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to leave room: \(error.localizedDescription)"
            }
        }
    }
    
    /// Update mood in current room
    func updateMood(_ mood: RoomMood) async {
        guard currentRoom != nil else { return }
        
        await livePresenceManager.updateMood(mood)
        
        await MainActor.run {
            self.latestEventMessage = "🎭 Mood updated to \(mood.emoji)"
        }
        
        // Clear message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.latestEventMessage = nil
        }
    }
    
    /// Delete a room (only if user is the creator)
    func deleteRoom(_ roomID: String) async {
        guard let room = rooms.first(where: { $0.id == roomID }),
              room.createdBy == AuthService.shared.currentUser?.id else {
            await MainActor.run {
                self.errorMessage = "You can only delete rooms you created"
            }
            return
        }
        
        do {
            try await roomService.deleteRoom(roomID)
            
            await MainActor.run {
                self.latestEventMessage = "🗑️ Room '\(room.name)' deleted"
            }
            
            // Clear message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.latestEventMessage = nil
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete room: \(error.localizedDescription)"
            }
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
    
    // MARK: - Utility Methods
    
    /// Refresh rooms data
    func refresh() async {
        await roomService.refresh()
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
        roomService.clearError()
    }
    
    /// Check if user can delete a room
    func canDeleteRoom(_ room: Room) -> Bool {
        return room.createdBy == AuthService.shared.currentUser?.id
    }
    
    /// Check if user is currently in a room
    var isInRoom: Bool {
        return currentRoom != nil
    }
    
    /// Get live users in current room
    func getLiveUsers() -> [String: RoomMood] {
        return livePresenceManager.getCurrentLiveUsers()
    }
}