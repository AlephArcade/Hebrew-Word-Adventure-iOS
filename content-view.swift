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
    import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var showingStartScreen = true
    
    var body: some View {
        ZStack {
            // Background color
            Color(red: 15/255, green: 20/255, blue: 25/255)
                .ignoresSafeArea()
            
            if showingStartScreen {
                StartScreenView(startGame: {
                    withAnimation {
                        showingStartScreen = false
                        gameState.startGame()
                    }
                })
            } else {
                // Main game content
                ZStack {
                    if gameState.completed {
                        GameOverView(gameState: gameState)
                    } else if gameState.inBonusRound {
                        BonusRoundView(gameState: gameState)
                    } else {
                        MainGameView(gameState: gameState)
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

// Start Screen View
struct StartScreenView: View {
    let startGame: () -> Void
    @State private var animating = false
    
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
                ForEach(["א", "ב", "ג", "ד", "ה"], id: \.self) { letter in
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
                }
            }
            .padding(.vertical, 30)
            
            Spacer()
            
            // Start button
            Button(action: startGame) {
                Text("START QUEST")
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
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}