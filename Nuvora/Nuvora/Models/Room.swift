import Foundation

// MARK: - Room Mood Enum
enum RoomMood: String, CaseIterable, Codable {
    case chill = "😌 Chill"
    case hype = "🔥 Hype"
    case study = "📚 Study"
    case karaoke = "🎤 Karaoke"

    // Enhanced initializer with fallback support
    init?(rawValue: String) {
        switch rawValue {
        case "😌 Chill", "chill": self = .chill
        case "🔥 Hype", "hype": self = .hype
        case "📚 Study", "study": self = .study
        case "🎤 Karaoke", "karaoke": self = .karaoke
        default: return nil
        }
    }

    var raw: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .chill: return "😌"
        case .hype: return "🔥"
        case .study: return "📚"
        case .karaoke: return "🎤"
        }
    }
    
    var title: String {
        switch self {
        case .chill: return "Chill"
        case .hype: return "Hype"
        case .study: return "Study"
        case .karaoke: return "Karaoke"
        }
    }
    
    var description: String {
        switch self {
        case .chill: return "Relax and unwind"
        case .hype: return "High energy vibes"
        case .study: return "Focus and productivity"
        case .karaoke: return "Sing and have fun"
        }
    }
}

// MARK: - Room Model
struct Room: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let participants: Int
    let maxParticipants: Int
    let isPrivate: Bool
    let mood: RoomMood
    let createdAt: Date?
    let updatedAt: Date?
    let createdBy: String?
    let description: String?
    let tags: [String]?
    
    // Custom coding keys for Supabase compatibility
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case participants
        case maxParticipants = "max_participants"
        case isPrivate = "is_private"
        case mood
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case description
        case tags
    }
    
    // Initializer with default values
    init(
        id: String = UUID().uuidString,
        name: String,
        participants: Int = 0,
        maxParticipants: Int = 10,
        isPrivate: Bool = false,
        mood: RoomMood,
        createdAt: Date? = Date(),
        updatedAt: Date? = Date(),
        createdBy: String? = nil,
        description: String? = nil,
        tags: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.participants = participants
        self.maxParticipants = maxParticipants
        self.isPrivate = isPrivate
        self.mood = mood
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.description = description
        self.tags = tags
    }
    
    // Custom decoder to handle date formatting
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        participants = try container.decode(Int.self, forKey: .participants)
        maxParticipants = try container.decode(Int.self, forKey: .maxParticipants)
        isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        mood = try container.decode(RoomMood.self, forKey: .mood)
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        
        // Handle date decoding with ISO8601 format
        let dateFormatter = ISO8601DateFormatter()
        
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = dateFormatter.date(from: createdAtString)
        } else {
            createdAt = nil
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
    
    // Custom encoder for date formatting
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(participants, forKey: .participants)
        try container.encode(maxParticipants, forKey: .maxParticipants)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encode(mood, forKey: .mood)
        try container.encodeIfPresent(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(tags, forKey: .tags)
        
        // Handle date encoding with ISO8601 format
        let dateFormatter = ISO8601DateFormatter()
        
        if let createdAt = createdAt {
            try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        }
        
        if let updatedAt = updatedAt {
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        }
    }
    
    // Computed properties
    var isFull: Bool {
        return participants >= maxParticipants
    }
    
    var hasSpace: Bool {
        return participants < maxParticipants
    }
    
    var participantPercentage: Double {
        guard maxParticipants > 0 else { return 0 }
        return Double(participants) / Double(maxParticipants)
    }
    
    var formattedCreatedAt: String {
        guard let createdAt = createdAt else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Room Extensions
extension Room {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "participants": participants,
            "max_participants": maxParticipants,
            "is_private": isPrivate,
            "mood": mood.rawValue
        ]
        
        if let createdBy = createdBy {
            dict["created_by"] = createdBy
        }
        
        if let description = description {
            dict["description"] = description
        }
        
        if let tags = tags {
            dict["tags"] = tags
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        if let createdAt = createdAt {
            dict["created_at"] = dateFormatter.string(from: createdAt)
        }
        
        if let updatedAt = updatedAt {
            dict["updated_at"] = dateFormatter.string(from: updatedAt)
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Room? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let participants = dict["participants"] as? Int,
              let maxParticipants = dict["max_participants"] as? Int,
              let isPrivate = dict["is_private"] as? Bool,
              let moodString = dict["mood"] as? String,
              let mood = RoomMood(rawValue: moodString) else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        let createdAt = (dict["created_at"] as? String).flatMap { dateFormatter.date(from: $0) }
        let updatedAt = (dict["updated_at"] as? String).flatMap { dateFormatter.date(from: $0) }
        let createdBy = dict["created_by"] as? String
        let description = dict["description"] as? String
        let tags = dict["tags"] as? [String]
        
        return Room(
            id: id,
            name: name,
            participants: participants,
            maxParticipants: maxParticipants,
            isPrivate: isPrivate,
            mood: mood,
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: createdBy,
            description: description,
            tags: tags
        )
    }
}

// MARK: - Sample Data
extension Room {
    static let sampleRooms: [Room] = [
        Room(
            name: "Study Session",
            participants: 3,
            maxParticipants: 8,
            mood: .study,
            description: "Focused study time for finals"
        ),
        Room(
            name: "Chill Vibes",
            participants: 5,
            maxParticipants: 10,
            mood: .chill,
            description: "Relaxing and unwinding"
        ),
        Room(
            name: "Hype Zone",
            participants: 7,
            maxParticipants: 12,
            mood: .hype,
            description: "High energy music and chat"
        ),
        Room(
            name: "Karaoke Night",
            participants: 4,
            maxParticipants: 6,
            mood: .karaoke,
            description: "Sing your heart out!"
        )
    ]
}