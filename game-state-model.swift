import Foundation
import Combine
import SwiftUI

class GameState: ObservableObject {
    // Published properties to update the UI automatically when they change
    @Published var active: Bool = false
    @Published var level: Int = 1
    @Published var currentWord: Word?
    @Published var shuffledLetters: [String] = []
    @Published var selectedLetters: [Int] = []
    @Published var score: Int = 0
    @Published var streak: Int = 0
    @Published var bonusActive: Bool = false
    @Published var hintsRemaining: Int = 15
    @Published var completed: Bool = false
    @Published var animatingCorrect: Bool = false
    @Published var wordsCompleted: Int = 0
    @Published var completedWords: [Int: [String]] = [:]
    @Published var currentLevelProgress: Double = 0
    @Published var inBonusRound: Bool = false
    @Published var bonusTimeRemaining: Int = 0
    @Published var bonusReward: BonusReward = BonusReward(extraHints: 0, scoreMultiplier: 1)
    @Published var lives: Int = 10
    @Published var maxLives: Int = 10
    @Published var currentBonusChallenge: BonusChallenge?
    @Published var message: String = ""
    @Published var showingMessage: Bool = false
    
    // Bonus round timer
    private var bonusTimer: Timer?
    
    // Word Banks - data imported from the JavaScript version
    let wordBanks: [Int: [Word]] = [
        2: [
            Word(hebrew: "אב", transliteration: "av", meaning: "father"),
            Word(hebrew: "אם", transliteration: "em", meaning: "mother"),
            Word(hebrew: "בא", transliteration: "ba", meaning: "comes"),
            Word(hebrew: "גן", transliteration: "gan", meaning: "garden"),
            Word(hebrew: "דג", transliteration: "dag", meaning: "fish"),
            Word(hebrew: "רע", transliteration: "ra", meaning: "bad"),
            Word(hebrew: "חג", transliteration: "chag", meaning: "holiday"),
            Word(hebrew: "שם", transliteration: "shem", meaning: "name"),
            Word(hebrew: "עץ", transliteration: "etz", meaning: "tree")
        ],
        3: [
            Word(hebrew: "יום", transliteration: "yom", meaning: "day"),
            Word(hebrew: "מים", transliteration: "mayim", meaning: "water"),
            Word(hebrew: "ילד", transliteration: "yeled", meaning: "boy"),
            Word(hebrew: "אור", transliteration: "or", meaning: "light"),
            Word(hebrew: "המן", transliteration: "haman", meaning: "Haman (Purim villain)"),
            Word(hebrew: "רעש", transliteration: "ra'ash", meaning: "noise"),
            Word(hebrew: "מלך", transliteration: "melech", meaning: "king"),
            Word(hebrew: "נס", transliteration: "nes", meaning: "miracle"),
            Word(hebrew: "אזן", transliteration: "ozen", meaning: "ear"),
            Word(hebrew: "שמח", transliteration: "sameach", meaning: "happy")
        ],
        4: [
            Word(hebrew: "שלום", transliteration: "shalom", meaning: "peace"),
            Word(hebrew: "תודה", transliteration: "toda", meaning: "thank you"),
            Word(hebrew: "ילדה", transliteration: "yalda", meaning: "girl"),
            Word(hebrew: "אסתר", transliteration: "esther", meaning: "Esther (Purim heroine)"),
            Word(hebrew: "משתה", transliteration: "mishteh", meaning: "feast"),
            Word(hebrew: "אדר", transliteration: "adar", meaning: "Adar (month of Purim)"),
            Word(hebrew: "רעשן", transliteration: "ra'ashan", meaning: "noisemaker"),
            Word(hebrew: "שושן", transliteration: "shushan", meaning: "Shushan (city)")
        ],
        5: [
            Word(hebrew: "מרדכי", transliteration: "mordechai", meaning: "Mordechai (Purim hero)"),
            Word(hebrew: "פורים", transliteration: "purim", meaning: "Purim holiday"),
            Word(hebrew: "משלוח", transliteration: "mishloach", meaning: "sending (gifts)"),
            Word(hebrew: "מגילה", transliteration: "megila", meaning: "scroll")
        ],
        6: [
            Word(hebrew: "תחפושת", transliteration: "tachposet", meaning: "costume (Purim)"),
            Word(hebrew: "אומנות", transliteration: "omanut", meaning: "art"),
            Word(hebrew: "מוזיקה", transliteration: "muzika", meaning: "music")
        ]
    ]
    
    // Bonus Challenges - converted from JavaScript
    let nikudChallenges: [[BonusChallenge]] = [
        // Level 1 (easy)
        [
            BonusChallenge(letter: "אָ", options: ["ah", "uh", "eh", "ee"], correct: "uh", sound: "kamatz", transliteration: "uh as in \"sun\""),
            BonusChallenge(letter: "בֵּ", options: ["ve", "bey", "bah", "buh"], correct: "bey", sound: "tzere", transliteration: "e as in \"they\""),
            BonusChallenge(letter: "גִּ", options: ["ghee", "gah", "go", "gu"], correct: "ghee", sound: "chirik", transliteration: "i as in \"machine\"")
        ],
        // Level 2 (medium)
        [
            BonusChallenge(letter: "דֹּ", options: ["doh", "dah", "duh", "di"], correct: "doh", sound: "cholam", transliteration: "o as in \"go\""),
            BonusChallenge(letter: "הֻ", options: ["hoo", "hi", "he", "ho"], correct: "hoo", sound: "kubutz", transliteration: "u as in \"flute\"")
        ],
        // Level 3 (harder)
        [
            BonusChallenge(letter: "חַ", options: ["cha", "chi", "chu", "che"], correct: "cha", sound: "patach", transliteration: "a as in \"father\""),
            BonusChallenge(letter: "טוּ", options: ["tu", "ti", "te", "ta"], correct: "tu", sound: "shuruk", transliteration: "u as in \"flute\""),
            BonusChallenge(letter: "יֶ", options: ["ye", "ya", "yo", "yu"], correct: "ye", sound: "segol", transliteration: "e as in \"set\"")
        ],
        // Level 4 (advanced)
        [
            BonusChallenge(letter: "כַּ", options: ["ka", "ke", "ki", "ku"], correct: "ka", sound: "patach", transliteration: "a as in \"father\""),
            BonusChallenge(letter: "לֹ", options: ["lo", "la", "li", "lu"], correct: "lo", sound: "cholam", transliteration: "o as in \"go\""),
            BonusChallenge(letter: "נוֹ", options: ["no", "na", "ni", "nu"], correct: "no", sound: "cholam malei", transliteration: "o as in \"go\"")
        ],
        // Level 5
        [
            BonusChallenge(letter: "נֹ", options: ["oh", "ah", "eh", "oo"], correct: "oh", sound: "cholam", transliteration: "as in \"Noach\""),
            BonusChallenge(letter: "יָ", options: ["yah", "yeh", "yee", "yuh"], correct: "yah", sound: "qamatz", transliteration: "as in \"Adam\""),
            BonusChallenge(letter: "מֹ", options: ["mo", "ma", "me", "mu"], correct: "mo", sound: "cholam", transliteration: "as in \"Moshe\"")
        ],
        // Level 6
        [
            BonusChallenge(letter: "אִי", options: ["a", "ee", "o", "u"], correct: "ee", sound: "chirik malei", transliteration: "ee as in \"seen\""),
            BonusChallenge(letter: "אֵי", options: ["ei", "i", "a", "u"], correct: "ei", sound: "tzere malei", transliteration: "ei as in \"veil\""),
            BonusChallenge(letter: "אֹ", options: ["o", "a", "e", "u"], correct: "o", sound: "cholam ḥaser", transliteration: "o as in \"go\"")
        ]
    ]
    
    // Methods
    func startGame() {
        // Reset all game state variables
        active = true
        level = 1
        currentWord = nil
        shuffledLetters = []
        selectedLetters = []
        score = 0
        streak = 0
        bonusActive = false
        hintsRemaining = 15
        completed = false
        animatingCorrect = false
        wordsCompleted = 0
        completedWords = [:]
        currentLevelProgress = 0
        inBonusRound = false
        bonusTimeRemaining = 0
        bonusReward = BonusReward(extraHints: 0, scoreMultiplier: 1)
        lives = 10
        maxLives = 10
        
        // Start the first word
        setupWord()
    }
    
    func setupWord() {
        let wordLength = getWordLengthForLevel(level: level)
        guard let wordsForLevel = wordBanks[wordLength] else { return }
        
        // Get available words that haven't been completed
        let availableWords = wordsForLevel.filter { word in
            guard let completedForLevel = completedWords[wordLength] else { return true }
            return !completedForLevel.contains(word.hebrew)
        }
        
        // If no words left, level up or end game
        if availableWords.isEmpty {
            if level < 6 {
                level += 1
                currentLevelProgress = 0
                showMessage("LEVEL UP! Now playing with \(getWordLengthForLevel(level: level)) letter words!")
                setupWord()
            } else {
                completed = true
            }
            return
        }
        
        // Select random word
        if let randomWord = availableWords.randomElement() {
            currentWord = randomWord
            
            // Shuffle letters
            shuffledLetters = currentWord!.hebrew.map { String($0) }
            shuffledLetters.shuffle()
            
            // Reset selections
            selectedLetters = []
            animatingCorrect = false
            
            // Update bonus status
            bonusActive = streak >= 3
        }
    }
    
    func getWordLengthForLevel(level: Int) -> Int {
        return level < 6 ? level + 1 : 6
    }
    
    func handleLetterSelect(index: Int) {
        // Prevent selection during animation
        if animatingCorrect { return }
        
        // Check if already selected
        if selectedLetters.contains(index) {
            // If this is the last letter selected, deselect it
            if selectedLetters.last == index {
                selectedLetters.removeLast()
            }
            return
        }
        
        // Add to selection
        selectedLetters.append(index)
        
        // Check if selection is complete
        if selectedLetters.count == currentWord?.hebrew.count {
            checkAnswer()
        }
    }
    
    func checkAnswer() {
        guard let currentWord = currentWord else { return }
        
        // Build the word from selected letters
        let selectedWord = selectedLetters.map { shuffledLetters[$0] }.joined()
        
        if selectedWord == currentWord.hebrew {
            // Correct answer
            animatingCorrect = true
            wordsCompleted += 1
            
            // Update completed words
            let wordLength = getWordLengthForLevel(level: level)
            if var completedForLevel = completedWords[wordLength] {
                completedForLevel.append(currentWord.hebrew)
                completedWords[wordLength] = completedForLevel
            } else {
                completedWords[wordLength] = [currentWord.hebrew]
            }
            
            // Update progress
            if let wordsInLevel = wordBanks[wordLength]?.count, wordsInLevel > 0 {
                currentLevelProgress = Double(completedWords[wordLength]?.count ?? 0) / Double(wordsInLevel) * 100
            }
            
            // Calculate points with bonus if streak is active
            var pointsEarned = currentWord.hebrew.count * 10
            
            if bonusActive {
                pointsEarned = Int(Double(pointsEarned) * 1.5) // 50% bonus
            }
            
            score += pointsEarned
            streak += 1
            
            // Update bonus status
            bonusActive = streak >= 3
            
            // Show appropriate message
            if bonusActive {
                showMessage("+\(pointsEarned) points with streak bonus! 🔥")
            } else {
                showMessage("AWESOME! +\(pointsEarned) points!")
            }
            
            // Delay before next word
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                
                let wordLength = self.getWordLengthForLevel(level: self.level)
                if let completedCount = self.completedWords[wordLength]?.count,
                   let totalWords = self.wordBanks[wordLength]?.count,
                   completedCount == totalWords {
                    // Level complete
                    if self.level < 6 {
                        self.startBonusRound()
                    } else {
                        self.completed = true
                    }
                } else {
                    // Continue with next word
                    self.setupWord()
                }
            }
        } else {
            // Incorrect answer
            lives = max(0, lives - 1)
            
            if lives <= 0 {
                showMessage("GAME OVER!")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.gameOver()
                }
                return
            }
            
            showMessage("Try again! Lost 1 life.")
            
            // Reset streak on error
            streak = 0
            bonusActive = false
            
            // Reset selection after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.selectedLetters = []
            }
        }
    }
    
    func gameOver() {
        // Game over logic
        active = false
        completed = true
    }
    
    func startBonusRound() {
        inBonusRound = true
        bonusTimeRemaining = 10 // 10 seconds for bonus round
        
        // Choose a random nikud challenge based on current level
        if level <= nikudChallenges.count, let levelChallenges = nikudChallenges[safe: level - 1], !levelChallenges.isEmpty {
            let randomIndex = Int.random(in: 0..<levelChallenges.count)
            currentBonusChallenge = levelChallenges[randomIndex]
            
            // Start the timer
            bonusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.bonusTimeRemaining -= 1
                
                if self.bonusTimeRemaining <= 0 {
                    self.bonusTimer?.invalidate()
                    self.endBonusRound(success: false) // Timeout
                }
            }
        } else {
            // Handle case where no challenges are available
            endBonusRound(success: false)
        }
    }
    
    func handleBonusSelection(selected: String) {
        bonusTimer?.invalidate() // Stop the timer
        
        guard let challenge = currentBonusChallenge else { return }
        
        let isCorrect = selected == challenge.correct
        
        if isCorrect {
            // Apply rewards
            bonusReward.extraHints += 3
            hintsRemaining += 3
            score += 30
            
            showMessage("CORRECT! +30 points and 3 bonus hints!")
            
            // End the bonus round after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.endBonusRound(success: true)
            }
        } else {
            // Wrong answer
            showMessage("Not quite right! Hint: \(challenge.transliteration)")
            
            // End after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.endBonusRound(success: false)
            }
        }
    }
    
    func endBonusRound(success: Bool) {
        inBonusRound = false
        bonusTimer?.invalidate()
        
        // Move to next level
        level += 1
        
        // Check if we've reached beyond the maximum level
        if level > 6 {
            completed = true
            return
        }
        
        // Otherwise, continue with normal level progression
        currentLevelProgress = 0
        showMessage("LEVEL UP! Now playing with \(getWordLengthForLevel(level: level)) letter words!")
        
        // Set up new word for the next level
        setupWord()
    }
    
    func resetSelection() {
        if animatingCorrect { return }
        selectedLetters = []
    }
    
    func getHint() {
        if hintsRemaining <= 0 || animatingCorrect { return }
        
        guard let currentWord = currentWord else { return }
        
        // Find the next letter position that needs to be filled
        var nextLetterPosition = 0
        
        // If the user has selected letters and they are correct, hint for the next position
        if !selectedLetters.isEmpty {
            // Check if the selected letters are correct so far
            let selectedWord = selectedLetters.map { shuffledLetters[$0] }.joined()
            let targetWordStart = String(currentWord.hebrew.prefix(selectedLetters.count))
            
            if selectedWord == targetWordStart {
                // Selected letters are correct, hint for the next position
                nextLetterPosition = selectedLetters.count
            } else {
                // Selected letters are incorrect, hint for the first position
                nextLetterPosition = 0
                // Clear incorrect selections before showing the hint
                selectedLetters = []
            }
        }
        
        // If all letters are already selected, no hint needed
        if nextLetterPosition >= currentWord.hebrew.count { return }
        
        // Get the correct letter for the next position
        let correctLetterIndex = currentWord.hebrew.index(currentWord.hebrew.startIndex, offsetBy: nextLetterPosition)
        let correctLetter = String(currentWord.hebrew[correctLetterIndex])
        
        // Find this letter in the shuffled array that's not already selected
        if let hintIndex = shuffledLetters.firstIndex(where: { letter in
            letter == correctLetter && !selectedLetters.contains(shuffledLetters.firstIndex(of: letter) ?? -1)
        }) {
            // Add this letter to the selection
            selectedLetters.append(hintIndex)
            hintsRemaining -= 1
            score = max(0, score - 5) // Penalty for using a hint
            
            showMessage("Hint: Letter \(nextLetterPosition + 1) selected")
            
            // If all letters are now selected, check the answer
            if selectedLetters.count == currentWord.hebrew.count {
                checkAnswer()
            }
        }
    }
    
    func showMessage(_ text: String) {
        message = text
        showingMessage = true
        
        // Hide message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showingMessage = false
        }
    }
}

// Extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
