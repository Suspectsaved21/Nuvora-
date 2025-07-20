import Foundation
import AVFoundation

final class AmbientSoundManager {
    static let shared = AmbientSoundManager()
    
    private var player: AVAudioPlayer?

    private init() {
        preparePlayer()
    }

    private func preparePlayer() {
        guard let url = Bundle.main.url(forResource: "lobby_ambient_loop", withExtension: "mp3") else {
            print("❌ Could not find ambient audio file.")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.3
        } catch {
            print("❌ Failed to load ambient audio: \(error)")
        }
    }

    func start() {
        player?.play()
    }

    func stop() {
        player?.stop()
    }
}

