import Foundation

/// Enum representing different mood states for users in a room
enum RoomMood: String, CaseIterable, Codable {
    case happy = "happy"
    case excited = "excited"
    case calm = "calm"
    case focused = "focused"
    case creative = "creative"
    case energetic = "energetic"
    case relaxed = "relaxed"
    case motivated = "motivated"
    case contemplative = "contemplative"
    case social = "social"
    
    /// Display name for the mood
    var displayName: String {
        switch self {
        case .happy:
            return "Happy"
        case .excited:
            return "Excited"
        case .calm:
            return "Calm"
        case .focused:
            return "Focused"
        case .creative:
            return "Creative"
        case .energetic:
            return "Energetic"
        case .relaxed:
            return "Relaxed"
        case .motivated:
            return "Motivated"
        case .contemplative:
            return "Contemplative"
        case .social:
            return "Social"
        }
    }
    
    /// Emoji representation of the mood
    var emoji: String {
        switch self {
        case .happy:
            return "😊"
        case .excited:
            return "🤩"
        case .calm:
            return "😌"
        case .focused:
            return "🎯"
        case .creative:
            return "🎨"
        case .energetic:
            return "⚡"
        case .relaxed:
            return "😎"
        case .motivated:
            return "💪"
        case .contemplative:
            return "🤔"
        case .social:
            return "🤝"
        }
    }
    
    /// Color associated with the mood (hex string)
    var colorHex: String {
        switch self {
        case .happy:
            return "#FFD700"
        case .excited:
            return "#FF6B6B"
        case .calm:
            return "#4ECDC4"
        case .focused:
            return "#45B7D1"
        case .creative:
            return "#96CEB4"
        case .energetic:
            return "#FECA57"
        case .relaxed:
            return "#A8E6CF"
        case .motivated:
            return "#FF8B94"
        case .contemplative:
            return "#DDA0DD"
        case .social:
            return "#98D8C8"
        }
    }
}
