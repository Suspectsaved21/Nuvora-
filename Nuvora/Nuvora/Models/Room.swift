import Foundation

enum RoomMood: String, CaseIterable, Codable {
    case chill = "😌 Chill"
    case hype = "🔥 Hype"
    case study = "📚 Study"
    case karaoke = "🎤 Karaoke"

    // For Firebase decoding fallback
    init?(rawValue: String) {
        switch rawValue {
        case "😌 Chill": self = .chill
        case "🔥 Hype": self = .hype
        case "📚 Study": self = .study
        case "🎤 Karaoke": self = .karaoke
        default: return nil
        }
    }

    var raw: String {
        return self.rawValue
    }
}

struct Room: Identifiable, Codable {
    let id: String
    let name: String
    let participants: Int
    let maxParticipants: Int
    let isPrivate: Bool
    let mood: RoomMood
}

extension Room {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "participants": participants,
            "maxParticipants": maxParticipants,
            "isPrivate": isPrivate,
            "mood": mood.rawValue
        ]
    }
}

