import AudioToolbox

class SoundManager {
    static let shared = SoundManager()

    func playPop() {
        AudioServicesPlaySystemSound(1104) // System click/pop sound
    }
}

