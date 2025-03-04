import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var showingStartScreen = true
    @State private var showingSettings = false
    @State private var showingDictionary = false
    @State private var showConfetti = false
    @State private var gameStartTime = Date()
    
    // For data persistence
    @ObservedObject private var gameDataManager = GameDataManager.shared
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 15/255, green: 20/255, blue: 25/255)
                .ignoresSafeArea()
            
            if showingStartScreen {
                StartScreenView(startGame: {
                    withAnimation {
                        startNewGame()
                    }
                }, continuePreviousGame: {
                    withAnimation {
                        continueGame()
                    }
                }, openSettings: {
                    showingSettings = true
                }, openDictionary: {
                    showingDictionary = true
                })
            } else {
                // Main game content
                ZStack {
                    if gameState.completed {
                        GameOverView(gameState: gameState) {
                            // Called when player wants to return to start screen
                            withAnimation {
                                showingStartScreen = true
                                
                                // Record game completion statistics
                                recordGameStatistics()
                            }
                        }
                    } else if gameState.inBonusRound {
                        BonusRoundView(gameState: gameState)
                    } else {
                        MainGameView(gameState: gameState)
                    }
                    
                    // Top toolbar for in-game menu
                    VStack {
                        HStack {
                            Button(action: {
                                AudioManager.shared.playButtonTapSound()
                                HapticManager.shared.selection()
                                
                                // Save current game state
                                saveGameState()
                                
                                withAnimation {
                                    showingStartScreen = true
                                }
                            }) {
                                Image(systemName: "house")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .accessibilityLabel("Home")
                            
                            Spacer()
                            
                            Button(action: {
                                AudioManager.shared.playButtonTapSound()
                                HapticManager.shared.selection()
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .accessibilityLabel("Settings")
                        }
                        .padding()
                        
                        Spacer()
                    }
                }
                .transition(.opacity)
                .confetti(isActive: $showConfetti)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingDictionary) {
            DictionaryView()
        }
        .withErrorHandling()
        .onAppear {
            // Check for a saved game on app launch
            checkForSavedGame()
        }
        .onDisappear {
            // Ensure cleanup when app is terminated
            gameState.cleanup()
        }
    }
    
    // MARK: - Game State Management
    
    /// Starts a new game
    private func startNewGame() {
        showingStartScreen = false
        gameState.startGame()
        gameStartTime = Date()
        
        // Clear saved game when starting new
        gameDataManager.clearSavedGameState()
        
        AudioManager.shared.playButtonTapSound()
        HapticManager.shared.mediumImpact()
    }
    
    /// Continues a previous game
    private func continueGame() {
        guard let savedState = gameDataManager.savedGameState else {
            // No saved game available
            startNewGame()
            return
        }
        
        showingStartScreen = false
        
        // Restore game state from saved state
        gameState.level = savedState.level
        gameState.score = savedState.score
        gameState.lives = savedState.lives
        gameState.hintsRemaining = savedState.hintsRemaining
        gameState.streak = savedState.streak
        gameState.completedWords = savedState.completedWords
        
        // Start from current level
        gameState.active = true
        gameState.setupWord()
        
        gameStartTime = Date()
        
        AudioManager.shared.playButtonTapSound()
        HapticManager.shared.mediumImpact()
    }
    
    /// Saves the current game state for continuing later
    private func saveGameState() {
        let state = SavedGameState(
            level: gameState.level,
            score: gameState.score,
            lives: gameState.lives,
            hintsRemaining: gameState.hintsRemaining,
            streak: gameState.streak,
            completedWords: gameState.completedWords,
            date: Date()
        )
        
        gameDataManager.saveGameState(state)
    }

    /// Checks for a saved game on app launch
    private func checkForSavedGame() {
        // If there's a saved game state, enable the continue button
        if gameDataManager.savedGameState != nil {
            // Any setup needed for the continue button
        }
    }

    /// Records game statistics after completion
    private func recordGameStatistics() {
        let gameTime = Date().timeIntervalSince(gameStartTime)
        
        // Calculate total words completed across all levels
        var totalWordsCompleted = 0
        for (_, words) in gameState.completedWords {
            totalWordsCompleted += words.count
        }
        
        // Record statistics
        gameDataManager.recordGameCompletion(
            score: gameState.score,
            level: gameState.level,
            wordsCompleted: totalWordsCompleted,
            time: gameTime
        )
        
        // Add high score if applicable
        gameDataManager.addHighScore(
            score: gameState.score,
            level: gameState.level,
            wordsCompleted: totalWordsCompleted
        )
        
        // Add learned words to dictionary
        for (_, words) in gameState.completedWords {
            let learnedWords = words.compactMap { hebrewWord -> Word? in
                // Find the word object for each completed Hebrew word string
                for (_, wordList) in gameState.wordBanks {
                    if let word = wordList.first(where: { $0.hebrew == hebrewWord }) {
                        return word
                    }
                }
                return nil
            }
            
            gameDataManager.addLearnedWords(learnedWords)
        }
    }
}

// Start Screen View
struct StartScreenView: View {
    let startGame: () -> Void
    let continuePreviousGame: () -> Void
    let openSettings: () -> Void
    let openDictionary: () -> Void
    
    @State private var animating = false
    @ObservedObject private var dataManager = GameDataManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Hebrew Word Adventure")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal)
                .offset(y: animating ? 0 : -20)
                .opacity(animating ? 1 : 0)
                .accessibilityAddTraits(.isHeader)
            
            // Subtitle
            Text("Master Hebrew letters by putting them in the right order!")
                .font(.headline)
                .foregroundColor(Color(white: 0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .offset(y: animating ? 0 : -15)
                .opacity(animating ? 1 : 0)
            
            // Special feature
            Text("Includes special Purim words!")
                .font(.subheadline)
                .foregroundColor(.yellow)
                .padding(10)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(10)
                .offset(y: animating ? 0 : -10)
                .opacity(animating ? 1 : 0)
            
            Spacer()
            
            // Hebrew letters animation
            HStack(spacing: 15) {
                ForEach(["ה", "ד", "ג", "ב", "א"], id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(radius: 5)
                        .rotation3DEffect(
                            .degrees(animating ? 0 : 180),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .accessibilityLabel("Hebrew letter \(letter)")
                }
            }
            .padding(.vertical, 30)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 15) {
                // Start button
                Button(action: startGame) {
                    Text("NEW GAME")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 220)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.yellow)
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: 5)
                }
                .offset(y: animating ? 0 : 20)
                .opacity(animating ? 1 : 0)
                .accessibilityHint("Start a new game from the beginning")
                
                // Continue button (only if there's a saved game)
                if dataManager.savedGameState != nil {
                    Button(action: continuePreviousGame) {
                        Text("CONTINUE")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 220)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                            )
                    }
                    .offset(y: animating ? 0 : 20)
                    .opacity(animating ? 1 : 0)
                    .accessibilityHint("Continue your previous game")
                }
                
                // Dictionary button
                Button(action: openDictionary) {
                    Text("DICTIONARY")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 220)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                .offset(y: animating ? 0 : 20)
                .opacity(animating ? 1 : 0)
                .accessibilityHint("View your learned Hebrew words")
                
                // Settings button
                Button(action: openSettings) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().stroke(Color.white, lineWidth: 2))
                }
                .padding(.top, 10)
                .offset(y: animating ? 0 : 20)
                .opacity(animating ? 1 : 0)
                .accessibilityLabel("Settings")
            }
            
            // Version info
            Text("v1.0")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 20)
                .opacity(animating ? 1 : 0)
        }
        .padding(.vertical, 50)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animating = true
            }
        }
        // Set consistent RTL environment for Hebrew content
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// Extension to add confetti functionality to any view
extension View {
    func confetti(isActive: Binding<Bool>) -> some View {
        ZStack {
            self
            
            if isActive.wrappedValue {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
