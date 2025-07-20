// import Foundation
// import Supabase

// /// LivePresenceManager keeps track of users who are currently present in a room,
// /// manages mood updates, and exposes real-time callbacks for the UI.
// /// Built for Supabase Swift SDK 2.3.0+ (realtimeV2).
// final class LivePresenceManager {
//     static let shared = LivePresenceManager()
    
//     // MARK: - Dependencies
//     private var client: SupabaseClient {
//         guard let client = SupabaseManager.shared.client else {
//             fatalError("Supabase client not initialized! Call SupabaseManager.shared.initialize() early in app startup.")
//         }
//         return client
//     }

//     // MARK: - Internal State
//     private var presenceChannel: RealtimeChannelV2?
//     private var currentRoomID: String?
//     private var currentMood: RoomMood?

//     // MARK: - Joining a Room
//     /// Call this when the user enters a room.
//     func join(roomID: String, mood: RoomMood) {
//         // leaveCurrentRoomIfNeeded()

//         // let channel = client.realtimeV2.channel("room:\(roomID)")
//         // self.presenceChannel = channel
//         // self.currentRoomID = roomID
//         // self.currentMood = mood

//         // channel.subscribe()

//         // Task {
//         //     do {
//         //         try await channel.track(["mood": mood.rawValue])
//         //     } catch {
//         //         print("❌ Failed to track mood presence: \(error)")
//         //     }
//         // }

//         // channel.on(.presence, event: "sync") { [weak self] message in
//         //     guard let self = self else { return }
//         //     self.handlePresenceUpdate(message: message)
//         // }
//     }

//     // MARK: - Leaving a Room
//     /// Call this when the user leaves a room.
//     func leave(roomID: String? = nil) {
//         // presenceChannel?.unsubscribe()
//         // presenceChannel = nil
//         // currentRoomID = nil
//         // currentMood = nil
//     }

//     // MARK: - Listen for Live User Updates
//     /// Subscribe to changes in the live user list (and their moods) in the current room.
//     /// Pass a closure that gets called every time the presence state changes.
//     func listenToLiveUsers(onChange: @escaping ([String: RoomMood]) -> Void) {
//         // self.onLiveUsersChange = onChange
//     }

//     // MARK: - Private
//     // private var onLiveUsersChange: (([String: RoomMood]) -> Void)?

//     /// Internal: handle presence update messages from Supabase
//     // private func handlePresenceUpdate(message: RealtimeMessage) {
//     //     var liveUsers: [String: RoomMood] = [:]
//     //     // Parse presence from the payload
//     //     if let dict = message.payload as? [String: Any],
//     //        let presence = dict["presence"] as? [String: Any] {
//     //         for (userID, state) in presence {
//     //             if let stateDict = state as? [String: Any],
//     //                let moodRaw = stateDict["mood"] as? String,
//     //                let mood = RoomMood(rawValue: moodRaw) {
//     //                 liveUsers[userID] = mood
//     //             }
//     //         }
//     //     }
//     //     // Notify the UI or view model
//     //     onLiveUsersChange?(liveUsers)
//     // }

//     // private func leaveCurrentRoomIfNeeded() {
//     //     if presenceChannel != nil {
//     //         presenceChannel?.unsubscribe()
//     //         presenceChannel = nil
//     //         currentRoomID = nil
//     //         currentMood = nil
//     //     }
//     // }
// }

