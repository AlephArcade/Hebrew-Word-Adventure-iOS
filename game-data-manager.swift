import Foundation
import SwiftUI
import Combine

/// Manages game data persistence, high scores, and learned words
class GameDataManager: ObservableObject {
    static let shared = GameDataManager()
    
    // MARK: - Published properties
    
    /// High scores list
    @Published var highScores: [HighScore] = []
    
    /// Dictionary of learned words for reference
    @Published var learnedWords: [Word] = []
    
    /// Current game progress for continuing where left off
    @Published var savedGameState: SavedGameState?
    
    /// Player statistics
    @Published var statistics: GameStatistics = GameStatistics()
    
    // MARK: - Private properties
    private let userDefaults = UserDefaults.standard
    private let logger = Logger.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // UserDefaults keys
    private struct Keys {
        static let highScores = "high_scores"
        static let learnedWords = "learned_words"
        static let savedGameState = "saved_game_state"
        static let statistics = "game_statistics"
        static let lastPlayedDate = "last_played_date"
    }
    
    // MARK: - Initialization
    private init() {
        loadData()
    }
    
    // MARK: - Data Loading
    
    /// Loads all saved game data from UserDefaults
    private func loadData() {
        loadHighScores()
        loadLearnedWords()
        loadSavedGameState()
        loadStatistics()
        
        // Update last played date
        userDefaults.set(Date(), forKey: Keys.lastPlayedDate)
        
        logger.log(.info, "Game data loaded successfully", category: Logger.Category.data)
    }
    
    /// Loads high scores from UserDefaults
    private func loadHighScores() {
        guard let data = userDefaults.data(forKey: Keys.highScores) else {
            highScores = []
            return
        }
        
        do {
            highScores = try decoder.decode([HighScore].self, from: data)
            highScores.sort { $0.score > $1.score } // Sort by highest score
        } catch {
            logger.logError(error, category: Logger.Category.data)
            highScores = []
        }
    }
    
    /// Loads learned words from UserDefaults
    private func loadLearnedWords() {
        guard let data = userDefaults.data(forKey: Keys.learnedWords) else {
            learnedWords = []
            return
        }
        
        do {
            learnedWords = try decoder.decode([Word].self, from: data)
        } catch {
            logger.logError(error, category: Logger.Category.data)
            learnedWords = []
        }
    }
    
    /// Loads saved game state for continuing
    private func loadSavedGameState() {
        guard let data = userDefaults.data(forKey: Keys.savedGameState) else {
            savedGameState = nil
            return
        }
        
        do {
            savedGameState = try decoder.decode(SavedGameState.self, from: data)
        } catch {
            logger.logError(error, category: Logger.Category.data)
            savedGameState = nil
        }
    }
    
    /// Loads game statistics from UserDefaults
    private func loadStatistics() {
        guard let data = userDefaults.data(forKey: Keys.statistics) else {
            statistics = GameStatistics()
            return
        }
        
        do {
            statistics = try decoder.decode(GameStatistics.self, from: data)
        } catch {
            logger.logError(error, category: Logger.Category.data)
            statistics = GameStatistics()
        }
    }
    
    // MARK: - Data Saving
    
    /// Saves all game data to UserDefaults
    func saveData() {
        saveHighScores()
        saveLearnedWords()
        saveStatistics()
        
        // Update last played date
        userDefaults.set(Date(), forKey: Keys.lastPlayedDate)
        
        logger.log(.info, "Game data saved successfully", category: Logger.Category.data)
    }
    
    /// Saves high scores to UserDefaults
    private func saveHighScores() {
        do {
            let data = try encoder.encode(highScores)
            userDefaults.set(data, forKey: Keys.highScores)
        } catch {
            logger.logError(error, category: Logger.Category.data)
        }
    }
    
    /// Saves learned words to UserDefaults
    private func saveLearnedWords() {
        do {
            let data = try encoder.encode(learnedWords)
            userDefaults.set(data, forKey: Keys.learnedWords)
        } catch {
            logger.logError(error, category: Logger.Category.data)
        }
    }
    
    /// Saves current game state for continuing later
    func saveGameState(_ state: SavedGameState) {
        do {
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: Keys.savedGameState)
            savedGameState = state
        } catch {
            logger.logError(error, category: Logger.Category.data)
        }
    }
    
    /// Clears saved game state (e.g., after completing a game)
    func clearSavedGameState() {
        userDefaults.removeObject(forKey: Keys.savedGameState)
        savedGameState = nil
    }
    
    /// Saves game statistics to UserDefaults
    private func saveStatistics() {
        do {
            let data = try encoder.encode(statistics)
            userDefaults.set(data, forKey: Keys.statistics)
        } catch {
            logger.logError(error, category: Logger.Category.data)
        }
    }
    
    // MARK: - High Score Management
    
    /// Adds a new high score, maintaining a maximum of 10 scores
    func addHighScore(score: Int, level: Int, wordsCompleted: Int) {
        let newScore = HighScore(
            id: UUID(),
            playerName: "",  // Can be updated later
            score: score,
            level: level,
            wordsCompleted: wordsCompleted,
            date: Date()
        )
        
        highScores.append(newScore)
        highScores.sort { $0.score > $1.score }
        
        // Keep only top 10 scores
        if highScores.count > 10 {
            highScores = Array(highScores.prefix(10))
        }
        
        saveHighScores()
        
        // Update statistics
        statistics.gamesPlayed += 1
        if !highScores.isEmpty && highScores[0].id == newScore.id {
            statistics.highestScore = newScore.score
        }
        saveStatistics()
    }
    
    /// Updates the name for a high score entry
    func updateHighScoreName(id: UUID, name: String) {
        if let index = highScores.firstIndex(where: { $0.id == id }) {
            highScores[index].playerName = name
            saveHighScores()
        }
    }
    
    // MARK: - Learned Words Management
    
    /// Adds a word to the learned words dictionary
    func addLearnedWord(_ word: Word) {
        guard !learnedWords.contains(where: { $0.id == word.id }) else {
            // Word already exists in learned words
            return
        }
        
        learnedWords.append(word)
        saveLearnedWords()
        
        // Update statistics
        statistics.totalWordsLearned += 1
        saveStatistics()
    }
    
    /// Add multiple words to the learned dictionary
    func addLearnedWords(_ words: [Word]) {
        var newWordsAdded = 0
        
        for word in words {
            if !learnedWords.contains(where: { $0.id == word.id }) {
                learnedWords.append(word)
                newWordsAdded += 1
            }
        }
        
        if newWordsAdded > 0 {
            saveLearnedWords()
            
            // Update statistics
            statistics.totalWordsLearned += newWordsAdded
            saveStatistics()
        }
    }
    
    /// Gets learned words filtered by level or search term
    func getLearnedWords(filterLevel: Int? = nil, searchTerm: String = "") -> [Word] {
        var filtered = learnedWords
        
        // Filter by level if specified
        if let level = filterLevel {
            let wordLength = level < 6 ? level + 1 : 6
            filtered = filtered.filter { $0.hebrew.count == wordLength }
        }
        
        // Filter by search term if not empty
        if !searchTerm.isEmpty {
            filtered = filtered.filter {
                $0.hebrew.lowercased().contains(searchTerm.lowercased()) ||
                $0.transliteration.lowercased().contains(searchTerm.lowercased()) ||
                $0.meaning.lowercased().contains(searchTerm.lowercased())
            }
        }
        
        return filtered
    }
    
    // MARK: - Statistics Management
    
    /// Records a completed game
    func recordGameCompletion(score: Int, level: Int, wordsCompleted: Int, time: TimeInterval) {
        statistics.gamesPlayed += 1
        statistics.totalScore += score
        statistics.averageScore = statistics.totalScore / statistics.gamesPlayed
        statistics.highestLevel = max(statistics.highestLevel, level)
        statistics.totalWordsCompleted += wordsCompleted
        
        if score > statistics.highestScore {
            statistics.highestScore = score
        }
        
        // Record time statistics
        statistics.totalPlayTime += time
        statistics.averageGameTime = statistics.totalPlayTime / Double(statistics.gamesPlayed)
        
        saveStatistics()
    }
    
    /// Records a hint used
    func recordHintUsed() {
        statistics.hintsUsed += 1
        saveStatistics()
    }
    
    /// Records a bonus round completion
    func recordBonusRoundCompletion(success: Bool) {
        statistics.bonusRoundsPlayed += 1
        if success {
            statistics.bonusRoundsCompleted += 1
        }
        saveStatistics()
    }
    
    /// Resets all game statistics
    func resetStatistics() {
        statistics = GameStatistics()
        saveStatistics()
    }
}

// MARK: - Data Models

/// Model for saved high scores
struct HighScore: Identifiable, Codable {
    let id: UUID
    var playerName: String
    let score: Int
    let level: Int
    let wordsCompleted: Int
    let date: Date
}

/// Model for saving game state to continue later
struct SavedGameState: Codable {
    let level: Int
    let score: Int
    let lives: Int
    let hintsRemaining: Int
    let streak: Int
    let completedWords: [Int: [String]]
    let date: Date
}

/// Model for game statistics
struct GameStatistics: Codable {
    var gamesPlayed: Int = 0
    var totalScore: Int = 0
    var averageScore: Int = 0
    var highestScore: Int = 0
    var highestLevel: Int = 0
    var totalWordsLearned: Int = 0
    var totalWordsCompleted: Int = 0
    var hintsUsed: Int = 0
    var bonusRoundsPlayed: Int = 0
    var bonusRoundsCompleted: Int = 0
    var totalPlayTime: TimeInterval = 0
    var averageGameTime: TimeInterval = 0
}

// MARK: - Extensions
