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
                } else {
                    // Game completed successfully
                    Text("QUEST COMPLETE!")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding()
                    
                    // Trophy image for success
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 10)
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
                        
                        VStack {
                            Text("WORDS")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(totalWordsCompleted)")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // New high score notification if applicable
                    if isHighScore() {
                        Text("NEW HIGH SCORE!")
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .padding(.vertical, 10)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
                
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
                    }
                    
                    // Play again button
                    Button(action: {
                        HapticManager.shared.mediumImpact()
                        AudioManager.shared.playButtonTapSound()
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
                    // Play completion sound
                    AudioManager.shared.playGameCompleteSound()
                    HapticManager.shared.success()
                }
                
                // Check for high score
                checkForHighScore()
            }
            
            // High score name input sheet
            if showingNameInput {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Do nothing, prevent taps from passing through
                    }
                
                VStack(spacing: 20) {
                    Text("NEW HIGH SCORE!")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text("\(gameState.score) points")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    TextField("Enter your name", text: $playerName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.primary)
                    
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
                    
                    Button(action: {
                        showingNameInput = false
                    }) {
                        Text("SKIP")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
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
}
