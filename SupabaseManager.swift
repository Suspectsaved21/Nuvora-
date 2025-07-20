import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: "https://your-project-url.supabase.co"),
              let anonKey = "your-anon-key" as String? else {
            fatalError("Missing Supabase configuration")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    var currentUser: User? {
        client.auth.currentUser
    }
    
    var isSignedIn: Bool {
        currentUser != nil
    }
    
    // MARK: - Database Operations
    
    func fetchRooms() async throws -> [Room] {
        let response: [Room] = try await client
            .from("rooms")
            .select()
            .execute()
            .value
        return response
    }
    
    func createRoom(_ room: Room) async throws -> Room {
        let response: Room = try await client
            .from("rooms")
            .insert(room)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    func joinRoom(roomId: String, userId: String) async throws {
        try await client
            .from("room_participants")
            .insert(["room_id": roomId, "user_id": userId])
            .execute()
    }
    
    func leaveRoom(roomId: String, userId: String) async throws {
        try await client
            .from("room_participants")
            .delete()
            .eq("room_id", value: roomId)
            .eq("user_id", value: userId)
            .execute()
    }
}

// MARK: - Models

struct Room: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let createdBy: String
    let createdAt: Date
    let maxParticipants: Int
    let isPrivate: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case createdBy = "created_by"
        case createdAt = "created_at"
        case maxParticipants = "max_participants"
        case isPrivate = "is_private"
    }
}

struct RoomParticipant: Codable {
    let id: String
    let roomId: String
    let userId: String
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomId = "room_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}
