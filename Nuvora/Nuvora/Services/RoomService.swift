import Foundation
import Supabase
import Combine

/// Comprehensive room management service with Supabase integration
class RoomService: ObservableObject {
    static let shared = RoomService()
    
    @Published var rooms: [Room] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let tableName = "rooms"
    
    private init() {
        setupRealtimeSubscription()
    }
    
    // MARK: - Room CRUD Operations
    
    /// Fetch all rooms from Supabase
    func fetchRooms() async {
        guard let client = client else {
            await setError("Supabase client not initialized")
            return
        }
        
        await setLoading(true)
        
        do {
            let response: [Room] = try await client.database
                .from(tableName)
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.rooms = response
                self.isLoading = false
                self.errorMessage = nil
            }
            
            print("✅ Fetched \(response.count) rooms")
            
        } catch {
            await setError("Failed to fetch rooms: \(error.localizedDescription)")
        }
    }
    
    /// Create a new room
    func createRoom(_ room: Room) async throws -> Room {
        guard let client = client else {
            throw RoomServiceError.clientNotInitialized
        }
        
        await setLoading(true)
        
        do {
            let response: Room = try await client.database
                .from(tableName)
                .insert(room)
                .select()
                .single()
                .execute()
                .value
            
            await MainActor.run {
                self.rooms.insert(response, at: 0)
                self.isLoading = false
                self.errorMessage = nil
            }
            
            print("✅ Created room: \(response.name)")
            return response
            
        } catch {
            await setError("Failed to create room: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Update an existing room
    func updateRoom(_ room: Room) async throws -> Room {
        guard let client = client else {
            throw RoomServiceError.clientNotInitialized
        }
        
        await setLoading(true)
        
        do {
            let updatedRoom = Room(
                id: room.id,
                name: room.name,
                participants: room.participants,
                maxParticipants: room.maxParticipants,
                isPrivate: room.isPrivate,
                mood: room.mood,
                createdAt: room.createdAt,
                updatedAt: Date(),
                createdBy: room.createdBy,
                description: room.description,
                tags: room.tags
            )
            
            let response: Room = try await client.database
                .from(tableName)
                .update(updatedRoom)
                .eq("id", value: room.id)
                .select()
                .single()
                .execute()
                .value
            
            await MainActor.run {
                if let index = self.rooms.firstIndex(where: { $0.id == room.id }) {
                    self.rooms[index] = response
                }
                self.isLoading = false
                self.errorMessage = nil
            }
            
            print("✅ Updated room: \(response.name)")
            return response
            
        } catch {
            await setError("Failed to update room: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Delete a room
    func deleteRoom(_ roomId: String) async throws {
        guard let client = client else {
            throw RoomServiceError.clientNotInitialized
        }
        
        await setLoading(true)
        
        do {
            try await client.database
                .from(tableName)
                .delete()
                .eq("id", value: roomId)
                .execute()
            
            await MainActor.run {
                self.rooms.removeAll { $0.id == roomId }
                self.isLoading = false
                self.errorMessage = nil
            }
            
            print("✅ Deleted room: \(roomId)")
            
        } catch {
            await setError("Failed to delete room: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Join a room (increment participant count)
    func joinRoom(_ roomId: String) async throws -> Room {
        guard let client = client else {
            throw RoomServiceError.clientNotInitialized
        }
        
        guard let room = rooms.first(where: { $0.id == roomId }) else {
            throw RoomServiceError.roomNotFound
        }
        
        guard room.hasSpace else {
            throw RoomServiceError.roomFull
        }
        
        await setLoading(true)
        
        do {
            let response: Room = try await client.database
                .from(tableName)
                .update(["participants": room.participants + 1])
                .eq("id", value: roomId)
                .select()
                .single()
                .execute()
                .value
            
            await MainActor.run {
                if let index = self.rooms.firstIndex(where: { $0.id == roomId }) {
                    self.rooms[index] = response
                }
                self.isLoading = false
                self.errorMessage = nil
            }
            
            print("✅ Joined room: \(response.name)")
            return response
            
        } catch {
            await setError("Failed to join room: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Leave a room (decrement participant count)
    func leaveRoom(_ roomId: String) async throws -> Room {
        guard let client = client else {
            throw RoomServiceError.clientNotInitialized
        }
        
        guard let room = rooms.first(where: { $0.id == roomId }) else {
            throw RoomServiceError.roomNotFound
        }
        
        guard room.participants > 0 else {
            throw RoomServiceError.noParticipants
        }
        
        await setLoading(true)
        
        do {
            let response: Room = try await client.database
                .from(tableName)
                .update(["participants": room.participants - 1])
                .eq("id", value: roomId)
                .select()
                .single()
                .execute()
                .value
            
            await MainActor.run {
                if let index = self.rooms.firstIndex(where: { $0.id == roomId }) {
                    self.rooms[index] = response
                }
                self.isLoading = false
                self.errorMessage = nil
            }
            
            print("✅ Left room: \(response.name)")
            return response
            
        } catch {
            await setError("Failed to leave room: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Search and Filter
    
    /// Search rooms by name or description
    func searchRooms(query: String) async {
        guard let client = client else {
            await setError("Supabase client not initialized")
            return
        }
        
        guard !query.isEmpty else {
            await fetchRooms()
            return
        }
        
        await setLoading(true)
        
        do {
            let response: [Room] = try await client.database
                .from(tableName)
                .select()
                .or("name.ilike.%\(query)%,description.ilike.%\(query)%")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.rooms = response
                self.isLoading = false
                self.errorMessage = nil
            }
            
            print("✅ Found \(response.count) rooms for query: \(query)")
            
        } catch {
            await setError("Failed to search rooms: \(error.localizedDescription)")
        }
    }
    
    /// Filter rooms by mood
    func filterRoomsByMood(_ mood: RoomMood) async {
        guard let client = client else {
            await setError("Supabase client not initialized")
            return
        }
        
        await setLoading(true)
        
        do {
            let response: [Room] = try await client.database
                .from(tableName)
                .select()
                .eq("mood", value: mood.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.rooms = response
                self.isLoading = false
                self.errorMessage = nil
            }
            
            print("✅ Found \(response.count) rooms with mood: \(mood.rawValue)")
            
        } catch {
            await setError("Failed to filter rooms: \(error.localizedDescription)")
        }
    }
    
    /// Get rooms with available space
    func getAvailableRooms() async {
        guard let client = client else {
            await setError("Supabase client not initialized")
            return
        }
        
        await setLoading(true)
        
        do {
            let response: [Room] = try await client.database
                .from(tableName)
                .select()
                .lt("participants", value: "max_participants")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.rooms = response
                self.isLoading = false
                self.errorMessage = nil
            }
            
            print("✅ Found \(response.count) available rooms")
            
        } catch {
            await setError("Failed to get available rooms: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Real-time Subscription
    
    private func setupRealtimeSubscription() {
        guard let client = client else { return }
        
        Task {
            let channel = client.realtime.channel("public:rooms")
            
            await channel.on(.insert) { [weak self] message in
                if let room = self?.parseRoomFromMessage(message) {
                    DispatchQueue.main.async {
                        self?.rooms.insert(room, at: 0)
                    }
                    print("🔄 Room inserted: \(room.name)")
                }
            }
            
            await channel.on(.update) { [weak self] message in
                if let room = self?.parseRoomFromMessage(message) {
                    DispatchQueue.main.async {
                        if let index = self?.rooms.firstIndex(where: { $0.id == room.id }) {
                            self?.rooms[index] = room
                        }
                    }
                    print("🔄 Room updated: \(room.name)")
                }
            }
            
            await channel.on(.delete) { [weak self] message in
                if let roomId = message.payload["old"]?["id"] as? String {
                    DispatchQueue.main.async {
                        self?.rooms.removeAll { $0.id == roomId }
                    }
                    print("🔄 Room deleted: \(roomId)")
                }
            }
            
            await channel.subscribe()
            print("✅ Subscribed to room changes")
        }
    }
    
    private func parseRoomFromMessage(_ message: RealtimeMessage) -> Room? {
        guard let payload = message.payload["new"] as? [String: Any] else { return nil }
        return Room.fromDictionary(payload)
    }
    
    // MARK: - Helper Methods
    
    private func setLoading(_ loading: Bool) async {
        await MainActor.run {
            self.isLoading = loading
        }
    }
    
    private func setError(_ error: String) async {
        await MainActor.run {
            self.errorMessage = error
            self.isLoading = false
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Refresh rooms data
    func refresh() async {
        await fetchRooms()
    }
}

// MARK: - Room Service Errors

enum RoomServiceError: LocalizedError {
    case clientNotInitialized
    case roomNotFound
    case roomFull
    case noParticipants
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "Room service is not initialized"
        case .roomNotFound:
            return "Room not found"
        case .roomFull:
            return "Room is full"
        case .noParticipants:
            return "No participants to remove"
        case .invalidData:
            return "Invalid room data"
        }
    }
}