import SwiftUI

struct MainGameView: View {
    @ObservedObject var gameState: GameState
    @State private var showConfetti = false
    @State private var previousAnimatingCorrect = false
    
    // Access data and audio managers
    @ObservedObject private var dataManager = GameDataManager.shared
    @ObservedObject private var audioManager = AudioManager.shared
    
    // Timer reference for proper cleanup
    @State private var animationTimer: Timer?
    
    // Helper function to determine grid columns based on level
    private func gridColumns() -> [GridItem] {
        let columns: Int
        switch gameState.level {
        case 1, 2, 3:
            columns = 2
        case 4, 5, 6:
            columns = 3
        default:
            columns = 2
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 15/255, green: 20/255, blue: 25/255)
                .ignoresSafeArea()
            
            VStack(spacing: 10) {
                // Top stats bar
                HStack {
                    // Level
                    VStack(alignment: .leading) {
                        Text("LEVEL")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(gameState.level)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Level progress
                        if let wordLength = gameState.wordBanks[gameState.getWordLengthForLevel(level: gameState.level)],
                           let completed = gameState.completedWords[gameState.getWordLengthForLevel(level: gameState.level)]?.count {
                            Text("\(completed)/\(wordLength.count)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Level \(gameState.level)")
                    
                    Spacer()
                    
                    // Score
                    VStack {
                        Text("SCORE")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(gameState.score)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Score \(gameState.score)")
                    
                    Spacer()
                    
                    // Lives (hearts) - removed the "LIVES" text as requested
                    VStack {
                        HStack(spacing: 2) {
                            ForEach(0..<(gameState.maxLives/2), id: \.self) { index in
                                if gameState.lives > index * 2 {
                                    if gameState.lives > index * 2 + 1 {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.red)
                                    } else {
                                        Image(systemName: "heart.lefthalf.fill")
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    Image(systemName: "heart")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Lives \(gameState.lives) out of \(gameState.maxLives)")
                }
                .padding()
                .background(Color(white: 0.15))
                .cornerRadius(10)
                
                // Progress Bar
                ProgressView(value: gameState.currentLevelProgress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.orange))
                    .padding(.horizontal)
                    .accessibilityValue("\(Int(gameState.currentLevelProgress))% complete")
                
                // Word to find
                VStack {
                    if let currentWord = gameState.currentWord {
                        Text(currentWord.transliteration.uppercased())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(currentWord.meaning)
                            .font(.subheadline)
                            .foregroundColor(Color(white: 0.8))
                            .padding(.bottom, 5)
                    }
                }
                .padding()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Find the word \(gameState.currentWord?.transliteration ?? ""), meaning \(gameState.currentWord?.meaning ?? "")")
                
                // Streak display
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .foregroundColor(i < gameState.streak ? .yellow : Color(white: 0.3))
                    }
                    
                    if gameState.bonusActive {
                        Text("x1.5")
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.3))
                            )
                            .offset(x: 5)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Streak \(gameState.streak) out of 3. \(gameState.bonusActive ? "Bonus active" : "")")
                
                // Letter tiles grid
                LazyVGrid(columns: gridColumns(), spacing: 10) {
                    ForEach(Array(gameState.shuffledLetters.enumerated()), id: \.offset) { index, letter in
                        LetterTileView(
                            letter: letter,
                            isSelected: gameState.selectedLetters.contains(index),
                            selectionOrder: gameState.selectedLetters.firstIndex(of: index).map { $0 + 1 },
                            animatingCorrect: gameState.animatingCorrect && gameState.selectedLetters.contains(index),
                            animatingIncorrect: gameState.animatingIncorrect && gameState.selectedLetters.contains(index),
                            onTap: {
                                if !gameState.selectedLetters.contains(index) {
                                    // Play sound effect when selecting a letter
                                    AudioManager.shared.playLetterSelectSound()
                                    HapticManager.shared.selection()
                                }
                                gameState.handleLetterSelect(index: index)
                            }
                        )
                        .accessibilityLabel("Letter \(letter)\(gameState.selectedLetters.contains(index) ? ", selected" : "")")
                        .accessibilityHint("Tap to select")
                    }
                }
                .padding()
                
                // Answer slots
                HStack(spacing: 8) {
                    // Reversed for Hebrew right-to-left
                    ForEach(0..<(gameState.currentWord?.hebrew.count ?? 0), id: \.self) { index in
                        AnswerSlotView(
                            letter: index < gameState.selectedLetters.count ? gameState.shuffledLetters[gameState.selectedLetters[index]] : "",
                            isCorrect: gameState.animatingCorrect,
                            isIncorrect: gameState.animatingIncorrect,
                            index: index
                        )
                        .accessibilityLabel("Answer slot \(index + 1): \(index < gameState.selectedLetters.count ? gameState.shuffledLetters[gameState.selectedLetters[index]] : "empty")")
                    }
                }
                .environment(\.layoutDirection, .rightToLeft) // Hebrew is RTL
                .padding()
                
                // Controls
                HStack(spacing: 20) {
                    // Reset button
                    Button(action: {
                        AudioManager.shared.playButtonTapSound()
                        HapticManager.shared.mediumImpact()
                        gameState.resetSelection()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().stroke(Color.white, lineWidth: 2))
                    }
                    .disabled(gameState.animatingCorrect)
                    .opacity(gameState.animatingCorrect ? 0.5 : 1)
                    .accessibilityLabel("Reset selection")
                    
                    // Hint button
                    Button(action: {
                        AudioManager.shared.playHintSound()
                        HapticManager.shared.warning()
                        gameState.getHint()
                        GameDataManager.shared.recordHintUsed()
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 60, height: 60)
                            
                            VStack(spacing: 0) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                
                                Text("\(gameState.hintsRemaining)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(gameState.hintsRemaining <= 0 || gameState.animatingCorrect)
                    .opacity(gameState.hintsRemaining <= 0 || gameState.animatingCorrect ? 0.5 : 1)
                    .accessibilityLabel("Use hint, \(gameState.hintsRemaining) remaining")
                }
                .padding(.bottom)
                
                // Reserved space for message to prevent layout shifts
                ZStack {
                    // Transparent placeholder to reserve space
                    Color.clear
                        .frame(height: 60)
                    
                    // Message display
                    if gameState.showingMessage {
                        Text(gameState.message)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeInOut, value: gameState.showingMessage)
                            .accessibilityLabel("Message: \(gameState.message)")
                    }
                }
            }
            .padding()
            
            // Add confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Check for changes in animatingCorrect state
            setupAnimationTimer()
        }
        .onDisappear {
            // Clean up timer resources
            cleanupAnimationTimer()
        }
        // Force update the view when game state changes
        .id("game-view-\(gameState.animatingCorrect)-\(gameState.animatingIncorrect)-\(gameState.score)")
        // Apply RTL for entire Hebrew-language game UI
        .environment(\.layoutDirection, .rightToLeft)
    }
    
    // This function handles the confetti animation by watching for state changes
    private func setupAnimationTimer() {
        // Clean up existing timer if any
        cleanupAnimationTimer()
        
        // Create a new timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            if gameState.animatingCorrect && !previousAnimatingCorrect {
                previousAnimatingCorrect = true
                showConfetti = true
                AudioManager.shared.playCorrectAnswerSound()
                HapticManager.shared.success()
                
                // Hide confetti after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.showConfetti = false
                }
            } else if !gameState.animatingCorrect {
                previousAnimatingCorrect = false
            }
        }
        
        // Add to run loop
        if let timer = animationTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    // Clean up timer resources
    private func cleanupAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// Letter Tile Component
struct LetterTileView: View {
    let letter: String
    let isSelected: Bool
    let selectionOrder: Int?
    let animatingCorrect: Bool
    let animatingIncorrect: Bool
    let onTap: () -> Void
    
    @State private var animationAmount: CGFloat = 1.0
    @State private var colorAnimation: Double = 0.0
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Tile background with conditional color
                RoundedRectangle(cornerRadius: 8)
                    .fill(tileColor)
                    .shadow(radius: 2)
                    .aspectRatio(1, contentMode: .fit)
                
                // Letter text
                Text(letter)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color(red: 0.06, green: 0.08, blue: 0.10)) // Dark color
                
                // Selection order indicator
                if let order = selectionOrder {
                    Text("\(order)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                        .position(x: 60, y: 20)
                }
            }
            // Pulse animation for correct/incorrect answers
            .scaleEffect(animationAmount)
        }
        .disabled(isSelected || animatingCorrect || animatingIncorrect)
        .onAppear {
            setupTileAnimation()
        }
        .onChange(of: animatingCorrect) {
            setupTileAnimation()
        }
        .onChange(of: animatingIncorrect) {
            setupTileAnimation()
        }
        // Create a unique ID to force refresh when animation state changes
        .id("\(letter)-\(isSelected ? 1 : 0)-\(animatingCorrect ? 1 : 0)-\(animatingIncorrect ? 1 : 0)")
    }
    
    // Computed property for tile color based on state
    private var tileColor: Color {
        if animatingCorrect && isSelected {
            // Flash between green and yellow for correct answers
            return colorAnimation > 0.5 ? Color.green : Color.yellow
        } else if animatingIncorrect && isSelected {
            // Red for incorrect answers
            return Color.red
        } else if isSelected {
            // Regular selection color
            return Color.green
        } else {
            // Default tile color
            return Color(red: 1, green: 0.97, blue: 0.88) // FFF8E1 color
        }
    }
    
    private func setupTileAnimation() {
        // Reset animation values
        animationAmount = 1.0
        colorAnimation = 0.0
        
        // Start animation if correct answer
        if animatingCorrect && isSelected {
            // Pulse scale animation
            withAnimation(Animation.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                animationAmount = 1.1
            }
            
            // Color flashing animation
            withAnimation(Animation.easeInOut(duration: 0.4).repeatForever()) {
                colorAnimation = 1.0
            }
            
            // Reset scale animation after completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    animationAmount = 1.0
                }
            }
        }
        
        // Start animation if incorrect answer
        else if animatingIncorrect && isSelected {
            // Shake animation
            withAnimation(Animation.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true)) {
                animationAmount = 0.9
            }
            
            // Reset after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    animationAmount = 1.0
                }
            }
        }
    }
}

// Answer Slot Component
struct AnswerSlotView: View {
    let letter: String
    let isCorrect: Bool
    let isIncorrect: Bool
    let index: Int
    
    @State private var animationAmount: CGFloat = 1.0
    @State private var hasAnimated: Bool = false
    @State private var flashingColor: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(slotColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .accessibleFrame()
            
            Text(letter)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(animationAmount)
        .onAppear {
            setupAnimation()
        }
        .onChange(of: isCorrect) {
            setupAnimation()
        }
        .onChange(of: isIncorrect) {
            setupAnimation()
        }
        // Create a unique ID to force refresh when state changes
        .id("\(letter)-\(isCorrect ? 1 : 0)-\(isIncorrect ? 1 : 0)-\(index)")
    }
    
    // Computed property for slot color
    private var slotColor: Color {
        if isCorrect {
            return flashingColor ? Color.yellow : Color.green
        } else if isIncorrect {
            return Color.red
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private func setupAnimation() {
        // Reset animation state
        animationAmount = 1.0
        flashingColor = false
        
        // Only animate when correct or incorrect
        if isCorrect && !hasAnimated {
            hasAnimated = true
            
            // Start flashing color animation
            withAnimation(Animation.easeInOut(duration: 0.4).repeatCount(5, autoreverses: true)) {
                flashingColor = true
            }
            
            // Add staggered animation delay based on index for right-to-left effect
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                // Start animation
                withAnimation(Animation.easeInOut(duration: 0.5).repeatCount(1, autoreverses: true)) {
                    animationAmount = 1.1
                }
                
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        animationAmount = 1.0
                    }
                }
            }
        } else if isIncorrect {
            // Shake animation for incorrect answers
            withAnimation(Animation.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true)) {
                animationAmount = 0.95
            }
            
            // Reset after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    animationAmount = 1.0
                }
            }
        } else {
            // Reset animated state when returning to normal
            hasAnimated = false
        }
    }
}

// Extension to make frames accessible
extension View {
    func accessibleFrame() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }
}
