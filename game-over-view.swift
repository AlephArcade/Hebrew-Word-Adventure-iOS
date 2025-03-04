import SwiftUI

struct GameOverView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject private var dataManager = GameDataManager.shared
    @ObservedObject private var audioManager = AudioManager.shared
    
    // Callback for returning to start screen
    var onReturn: () -> Void
    
    // State for name input
    @State private var playerName: String = ""
    @State private var showingNameInput: Bool = false
    @State private var highScoreID: UUID? = nil
    
    // State for animations and cleanup
    @State private var showingConfetti: Bool = false
    @State private var confettiTask: DispatchWorkItem? = nil
    
    // Calculate total words completed across all levels
    private var totalWordsCompleted: Int {
        var total = 0
        for (_, words) in gameState.completedWords {
            total += words.count
        }
        return total
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 15/255, green: 20/255, blue: 25/255)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Game over header
                if gameState.lives <= 0 {
                    // Game over due to running out of lives
                    Text("GAME OVER")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.red)
                        .padding()
                        .accessibility(addTraits: .isHeader)
                } else {
                    // Game completed successfully
                    Text("QUEST COMPLETE!")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding()
                        .accessibility(addTraits: .isHeader)
                    
                    // Trophy image for success
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 10)
                        .accessibility(hidden: true)
                }
                
                // Score and stats
                VStack(spacing: 15) {
                    Text("FINAL SCORE")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("\(gameState.score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Divider()
                        .background(Color.gray)
                        .padding(.horizontal, 50)
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text("LEVEL")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(gameState.level)")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibility(label: Text("Level \(gameState.level)"))
                        
                        VStack {
                            Text("WORDS")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(totalWordsCompleted)")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibility(label: Text("Words completed: \(totalWordsCompleted)"))
                    }
                    
                    // New high score notification if applicable
                    if isHighScore() {
                        Text("NEW HIGH SCORE!")
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .padding(.vertical, 10)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
                .accessibilityElement(children: .combine)
                .accessibility(label: Text("Final score: \(gameState.score)"))
                
                // Action buttons
                VStack(spacing: 15) {
                    // High score button (only if it's a high score)
                    if isHighScore() {
                        Button(action: {
                            showingNameInput = true
                        }) {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("SAVE HIGH SCORE")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 240)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.yellow)
                            )
                        }
                        .accessibility(hint: Text("Save your high score with your name"))
                    }
                    
                    // Play again button
                    Button(action: {
                        HapticManager.shared.mediumImpact()
                        AudioManager.shared.playButtonTapSound()
                        
                        // Explicitly set completed to false first for immediate UI update
                        gameState.completed = false
                        
                        // Then reset the game state
                        gameState.startGame()
                    }) {
                        Text("PLAY AGAIN")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 240)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                            )
                    }
                    .accessibility(hint: Text("Start a new game"))
                    
                    // Return to menu button
                    Button(action: {
                        HapticManager.shared.selection()
                        AudioManager.shared.playButtonTapSound()
                        onReturn()
                    }) {
                        Text("RETURN TO MENU")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 240)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .accessibility(hint: Text("Go back to the main menu"))
                }
                .padding(.top, 20)
            }
            .padding()
            .onAppear {
                if gameState.lives <= 0 {
                    // Play game over sound
                    AudioManager.shared.playGameOverSound()
                    HapticManager.shared.error()
                } else {
                    // Play completion sound and show confetti
                    AudioManager.shared.playGameCompleteSound()
                    HapticManager.shared.success()
                    showConfetti()
                }
                
                // Check for high score
                checkForHighScore()
            }
            .onDisappear {
                // Clean up any animation resources
                confettiTask?.cancel()
                confettiTask = nil
                showingConfetti = false
            }
            
            // Add confetti effect for success
            if showingConfetti && gameState.lives > 0 {
                ImprovedConfettiView(
                    particleCount: 80,
                    colors: [
                        Color(red: 1.0, green: 0.85, blue: 0.35), // Yellowish
                        Color(red: 0.3, green: 0.69, blue: 0.31), // Greenish
                        Color(red: 0.13, green: 0.59, blue: 0.95), // Blueish
                        Color(red: 0.91, green: 0.12, blue: 0.39), // Pinkish
                        Color(red: 0.61, green: 0.15, blue: 0.69)  // Purplish
                    ],
                    confettiSize: 15,
                    rainHeight: UIScreen.main.bounds.height * 1.2,
                    openingAngle: .degrees(30),
                    closingAngle: .degrees(150)
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibility(hidden: true)
            }
            
            // High score name input sheet
            if showingNameInput {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Do nothing, prevent taps from passing through
                    }
                    .accessibility(hidden: true)
                
                VStack(spacing: 20) {
                    Text("NEW HIGH SCORE!")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .accessibility(addTraits: .isHeader)
                    
                    Text("\(gameState.score) points")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    TextField("Enter your name", text: $playerName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.primary)
                        .accessibility(label: Text("Your name for high score"))
                    
                    Button(action: {
                        saveHighScore()
                        showingNameInput = false
                    }) {
                        Text("SAVE")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.yellow)
                            .cornerRadius(8)
                    }
                    .accessibility(hint: Text("Save name and high score"))
                    
                    Button(action: {
                        showingNameInput = false
                    }) {
                        Text("SKIP")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .accessibility(hint: Text("Skip saving name"))
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(12)
                .shadow(radius: 10)
                .frame(width: 300)
                .transition(.opacity)
                .zIndex(1)
            }
        }
        // Animate the view appearing
        .transition(.opacity)
        .animation(.easeIn, value: gameState.completed)
    }
    
    // MARK: - High Score Methods
    
    /// Checks if the current score qualifies for a high score
    private func isHighScore() -> Bool {
        // If there are less than 10 high scores, any score qualifies
        if dataManager.highScores.count < 10 {
            return gameState.score > 0
        }
        
        // Otherwise, check if score is higher than the lowest high score
        return gameState.score > 0 && gameState.score > dataManager.highScores.last?.score ?? 0
    }
    
    /// Checks for high score and prepares for name input if needed
    private func checkForHighScore() {
        if isHighScore() {
            // Add high score with empty name to get an ID
            dataManager.addHighScore(
                score: gameState.score,
                level: gameState.level,
                wordsCompleted: totalWordsCompleted
            )
            
            // Find the newly added score to get its ID
            if let newScore = dataManager.highScores.first(where: { $0.score == gameState.score && $0.playerName.isEmpty }) {
                highScoreID = newScore.id
                
                // Show name input after a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingNameInput = true
                }
            }
        }
    }
    
    /// Saves the high score with the player's name
    private func saveHighScore() {
        guard let id = highScoreID else { return }
        
        // Use a default name if none provided
        let name = playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Player" : playerName
        
        // Update the high score with the player's name
        dataManager.updateHighScoreName(id: id, name: name)
        
        // Play sound effect
        AudioManager.shared.playButtonTapSound()
        HapticManager.shared.success()
    }
    
    /// Shows the confetti animation
    private func showConfetti() {
        // Only show confetti for successful game completion
        if gameState.lives > 0 {
            showingConfetti = true
            
            // Cancel any existing task
            confettiTask?.cancel()
            
            // Schedule confetti to disappear
            let task = DispatchWorkItem {
                showingConfetti = false
            }
            confettiTask = task
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: task)
        }
    }
}
