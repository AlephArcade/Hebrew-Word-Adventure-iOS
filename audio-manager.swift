import Foundation
import AVFoundation

/// Manages all sound effects and audio settings in the app
class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    // MARK: - Published properties
    @Published var isMuted: Bool = false {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "audio_muted")
            if isMuted {
                self.stopAllSounds()
            }
        }
    }
    
    @Published var volume: Float = 0.8 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "audio_volume")
            updateVolume()
        }
    }
    
    // MARK: - Private properties
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let audioSession = AVAudioSession.sharedInstance()
    
    // Audio sound names
    struct SoundEffect {
        static let correctAnswer = "correct_answer"
        static let wrongAnswer = "wrong_answer"
        static let hintUsed = "hint_used"
        static let levelUp = "level_up"
        static let bonusRound = "bonus_round"
        static let gameOver = "game_over"
        static let gameComplete = "game_complete"
        static let buttonTap = "button_tap"
        static let letterSelect = "letter_select"
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        
        // Load saved audio settings
        self.isMuted = UserDefaults.standard.bool(forKey: "audio_muted")
        if let savedVolume = UserDefaults.standard.object(forKey: "audio_volume") as? Float {
            self.volume = savedVolume
        }
        
        // Configure audio session
        setupAudioSession()
        
        // Preload commonly used sounds
        preloadSound(SoundEffect.correctAnswer)
        preloadSound(SoundEffect.wrongAnswer)
        preloadSound(SoundEffect.letterSelect)
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
            
            // Monitor for audio session interruptions
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption),
                name: AVAudioSession.interruptionNotification,
                object: audioSession
            )
        } catch {
            Logger.shared.log(.error, "Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio session interrupted - pause all audio
            pauseAllSounds()
        case .ended:
            // Interruption ended - resume audio if needed
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                  AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) else {
                return
            }
            // Resume audio
            resumeAllSounds()
        @unknown default:
            break
        }
    }
    
    // MARK: - Sound Management
    
    /// Preloads a sound for faster playback later
    private func preloadSound(_ soundName: String) {
        if isMuted { return }
        
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            Logger.shared.log(.warning, "Sound file not found: \(soundName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            player.volume = self.volume
            audioPlayers[soundName] = player
        } catch {
            Logger.shared.log(.error, "Failed to preload sound '\(soundName)': \(error.localizedDescription)")
        }
    }
    
    /// Plays a sound effect once
    func playSound(_ soundName: String) {
        if isMuted { return }
        
        // If player exists, reuse it
        if let player = audioPlayers[soundName] {
            if !player.isPlaying {
                player.currentTime = 0
                player.play()
            } else {
                // Create another instance for overlapping sounds
                duplicateAndPlaySound(soundName)
            }
            return
        }
        
        // Otherwise, create and play
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            Logger.shared.log(.warning, "Sound file not found: \(soundName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.volume = volume
            player.play()
            audioPlayers[soundName] = player
        } catch {
            Logger.shared.log(.error, "Failed to play sound '\(soundName)': \(error.localizedDescription)")
        }
    }
    
    /// Creates a duplicate player for simultaneous sound playback
    private func duplicateAndPlaySound(_ soundName: String) {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        
        do {
            let duplicatePlayer = try AVAudioPlayer(contentsOf: soundURL)
            duplicatePlayer.volume = volume
            duplicatePlayer.play()
            
            // Use a unique key for the duplicate
            let uniqueKey = "\(soundName)_\(Date().timeIntervalSince1970)"
            audioPlayers[uniqueKey] = duplicatePlayer
            
            // Remove the duplicate after it finishes playing
            DispatchQueue.main.asyncAfter(deadline: .now() + duplicatePlayer.duration + 0.1) {
                self.audioPlayers.removeValue(forKey: uniqueKey)
            }
        } catch {
            Logger.shared.log(.error, "Failed to play duplicate sound: \(error.localizedDescription)")
        }
    }
    
    /// Updates volume for all active audio players
    private func updateVolume() {
        for player in audioPlayers.values {
            player.volume = volume
        }
    }
    
    /// Stops all currently playing sounds
    func stopAllSounds() {
        for player in audioPlayers.values {
            if player.isPlaying {
                player.stop()
            }
        }
    }
    
    /// Pauses all currently playing sounds
    func pauseAllSounds() {
        for player in audioPlayers.values {
            if player.isPlaying {
                player.pause()
            }
        }
    }
    
    /// Resumes all paused sounds
    func resumeAllSounds() {
        if isMuted { return }
        
        for player in audioPlayers.values {
            if !player.isPlaying {
                player.play()
            }
        }
    }
    
    /// Cleans up audio resources
    func cleanup() {
        stopAllSounds()
        audioPlayers.removeAll()
        
        do {
            try audioSession.setActive(false)
        } catch {
            Logger.shared.log(.error, "Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Convenience methods for game events
    
    func playCorrectAnswerSound() {
        playSound(SoundEffect.correctAnswer)
    }
    
    func playWrongAnswerSound() {
        playSound(SoundEffect.wrongAnswer)
    }
    
    func playHintSound() {
        playSound(SoundEffect.hintUsed)
    }
    
    func playLevelUpSound() {
        playSound(SoundEffect.levelUp)
    }
    
    func playBonusRoundSound() {
        playSound(SoundEffect.bonusRound)
    }
    
    func playGameOverSound() {
        playSound(SoundEffect.gameOver)
    }
    
    func playGameCompleteSound() {
        playSound(SoundEffect.gameComplete)
    }
    
    func playLetterSelectSound() {
        playSound(SoundEffect.letterSelect)
    }
    
    func playButtonTapSound() {
        playSound(SoundEffect.buttonTap)
    }
}
