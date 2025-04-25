import SpriteKit
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        configureAudioSession()
        setupBackgroundMusic()
        setupSoundEffects()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func setupBackgroundMusic() {
        print("Setting up background music...")
        if let path = Bundle.main.path(forResource: "background_music", ofType: "mp3") {
            print("Found background music file at: \(path)")
            let url = URL(fileURLWithPath: path)
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.prepareToPlay()
                backgroundMusicPlayer?.numberOfLoops = -1 // 无限循环
                backgroundMusicPlayer?.volume = 0.3 // 设置音量
                print("Successfully created background music player")
            } catch {
                print("Failed to load background music: \(error)")
            }
        } else {
            print("Background music file not found")
        }
    }
    
    private func setupSoundEffects() {
        print("Setting up sound effects...")
        
        // 配置所有音效
        let soundEffects = [
            "shipMove": "ship_move.mp3",
            "shipCollision": "ship_collision.mp3",
            "mothershipExplosion": "mothership_explosion.mp3"
        ]
        
        for (effectName, fileName) in soundEffects {
            if let path = Bundle.main.path(forResource: fileName.replacingOccurrences(of: ".mp3", with: ""), ofType: "mp3") {
                print("Found sound effect file: \(fileName)")
                let url = URL(fileURLWithPath: path)
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = 0.5 // 设置音效音量
                    soundEffectPlayers[effectName] = player
                    print("Successfully created player for: \(effectName)")
                } catch {
                    print("Failed to load sound effect \(effectName): \(error)")
                }
            } else {
                print("Sound effect file not found: \(fileName)")
            }
        }
        
        print("Loaded sound effects: \(soundEffectPlayers.keys.joined(separator: ", "))")
    }
    
    func playBackgroundMusic() {
        if backgroundMusicPlayer?.isPlaying == true {
            print("Background music is already playing")
            return
        }
        
        if let player = backgroundMusicPlayer {
            player.play()
            print("Started playing background music")
        } else {
            print("Background music player is not initialized")
        }
    }
    
    func stopBackgroundMusic() {
        if let player = backgroundMusicPlayer {
            player.stop()
            print("Stopped background music")
        }
    }
    
    func playSoundEffect(_ name: String, in scene: SKScene) {
        if let player = soundEffectPlayers[name] {
            // 如果音效正在播放，先重置到开始位置
            if player.isPlaying {
                player.currentTime = 0
            }
            player.play()
            print("Playing sound effect: \(name)")
        } else {
            print("Sound effect not found: \(name)")
        }
    }
} 
