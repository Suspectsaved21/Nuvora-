import Foundation
import SwiftUI
import Supabase

class RoomViewModel: ObservableObject {
    @Published var rooms: [Room] = []
    @Published var searchTerm: String = ""
    @Published var latestEventMessage: String?
    @Published var shouldTriggerConfetti = false

    // Make client always up to date and optional
    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    init() {
        Task {
            await fetchRooms()
        }
    }

    var filteredRooms: [Room] {
        if searchTerm.isEmpty {
            return rooms
        } else {
            return rooms.filter { $0.name.lowercased().contains(searchTerm.lowercased()) }
        }
    }

    func createRoom(name: String, maxParticipants: Int, isPrivate: Bool, mood: RoomMood) {
        let newRoom = Room(
            id: UUID().uuidString,
            name: name,
            participants: 1,
            maxParticipants: maxParticipants,
            isPrivate: isPrivate,
            mood: mood
        )

        Task {
            guard let client = client else {
                print("❌ Supabase client not available!")
                return
            }
            do {
                try await client.database
                    .from("rooms")
                    .insert(newRoom)
                    .execute()

                DispatchQueue.main.async {
                    self.latestEventMessage = "🚀 Room '\(name)' created!"
                    self.shouldTriggerConfetti = true
                }

                await fetchRooms()

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.latestEventMessage = nil
                    self.shouldTriggerConfetti = false
                }

            } catch {
                print("❌ Failed to create room: \(error.localizedDescription)")
            }
        }
    }

    func fetchRooms() async {
        guard let client = client else {
            print("❌ Supabase client not available!")
            return
        }
        do {
            let response: [Room] = try await client.database
                .from("rooms")
                .select()
                .execute()
                .value

            DispatchQueue.main.async {
                self.rooms = response
            }

        } catch {
            print("❌ Failed to fetch rooms: \(error.localizedDescription)")
        }
    }

    func joinRoom(roomID: String) {
        if let room = rooms.first(where: { $0.id == roomID }) {
            latestEventMessage = "🎉 Joined '\(room.name)'!"
            shouldTriggerConfetti = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.latestEventMessage = nil
                self.shouldTriggerConfetti = false
            }
        }
    }
}

