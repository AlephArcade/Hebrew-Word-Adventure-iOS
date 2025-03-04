import SwiftUI

struct MainGameView: View {
    @ObservedObject var gameState: GameState
    @State private var showConfetti = false
    @State private var previousAnimatingCorrect = false
    
    // Access data and audio managers
    @ObservedObject private var dataManager = GameDataManager.shared
    @ObservedObject private var audioManager = AudioManager.shared
    
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
                    
                    Spacer()
                    
                    // Lives (hearts)
                    VStack {
                        Text("LIVES")
                            .font(.caption)
                            .foregroundColor(.gray)
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
                }
                .padding()
                .background(Color(white: 0.15))
                .cornerRadius(10)
                
                // Progress Bar
                ProgressView(value: gameState.currentLevelProgress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.orange))
                    .padding(.horizontal)
                
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
                
                // Letter tiles grid
                LazyVGrid(columns: gridColumns(), spacing: 10) {
                    ForEach(Array(gameState.shuffledLetters.enumerated()), id: \.offset) { index, letter in
                        LetterTileView(
                            letter: letter,
                            isSelected: gameState.selectedLetters.contains(index),
                            selectionOrder: gameState.selectedLetters.firstIndex(of: index).map { $0 + 1 },
                            animatingCorrect: gameState.animatingCorrect && gameState.selectedLetters.contains(index),
                            onTap: {
                                if !gameState.selectedLetters.contains(index) {
                                    // Play sound effect when selecting a letter
                                    AudioManager.shared.playLetterSelectSound()
                                    HapticManager.shared.selection()
                                }
                                gameState.handleLetterSelect(index: index)
                            }
                        )
                    }
                }
                .padding()
                
                // Answer slots
                HStack(spacing: 8) {
                    // Reverse for Hebrew right-to-left
                    ForEach(0..<(gameState.currentWord?.hebrew.count ?? 0), id: \.self) { index in
                        AnswerSlotView(
                            letter: index < gameState.selectedLetters.count ? gameState.shuffledLetters[gameState.selectedLetters[index]] : "",
                            isCorrect: gameState.animatingCorrect,
                            index: index
                        )
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
                }
                .padding(.bottom)
                
                // Message
                if gameState.showingMessage {
                    Text(gameState.message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .animation(.easeInOut, value: gameState.showingMessage)
                }
            }
            .padding()
            
            // Add confetti overlay
            if showConfetti {
                ConfettiEffectView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Check for changes in animatingCorrect state
            checkForCorrectAnswer()
        }
        // Force update the view when game state changes
        .id("game-view-\(gameState.animatingCorrect)-\(gameState.score)")
    }
    
    // This function handles the confetti animation by watching for state changes
    private func checkForCorrectAnswer() {
        // Create a timer to check for changes in animatingCorrect
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if gameState.animatingCorrect && !previousAnimatingCorrect {
                previousAnimatingCorrect = true
                showConfetti = true
                AudioManager.shared.playCorrectAnswerSound()
                HapticManager.shared.success()
                
                // Hide confetti after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showConfetti = false
                }
            } else if !gameState.animatingCorrect {
                previousAnimatingCorrect = false
            }
        }
        
        // Add to run loop
        RunLoop.current.add(timer, forMode: .common)
    }
}

// Letter Tile Component
struct LetterTileView: View {
    let letter: String
    let isSelected: Bool
    let selectionOrder: Int?
    let animatingCorrect: Bool
    let onTap: () -> Void
    
    @State private var animationAmount: CGFloat = 1.0
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Tile background
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.green : Color(red: 1, green: 0.97, blue: 0.88)) // FFF8E1 color
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
            // Pulse animation for correct answers
            .scaleEffect(animationAmount)
        }
        .disabled(isSelected || animatingCorrect)
        .onAppear {
            // Start animation if correct answer
            if animatingCorrect && isSelected {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                    animationAmount = 1.1
                }
                
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    animationAmount = 1.0
                }
            }
        }
        // Create a unique ID to force refresh when animation state changes
        .id("\(letter)-\(isSelected ? 1 : 0)-\(animatingCorrect ? 1 : 0)")
    }
}

// Answer Slot Component
struct AnswerSlotView: View {
    let letter: String
    let isCorrect: Bool
    let index: Int
    
    @State private var animationAmount: CGFloat = 1.0
    @State private var hasAnimated: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isCorrect ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
            
            Text(letter)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(animationAmount)
        .onAppear {
            // Only animate when correct
            if isCorrect && !hasAnimated {
                hasAnimated = true
                
                // Add staggered animation delay based on index
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                    // Start animation
                    withAnimation(Animation.easeInOut(duration: 0.5).repeatCount(1, autoreverses: true)) {
                        animationAmount = 1.1
                    }
                    
                    // Reset animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        animationAmount = 1.0
                    }
                }
            }
        }
        // Create a unique ID to force refresh when state changes
        .id("\(letter)-\(isCorrect ? 1 : 0)-\(index)")
    }
}

// Simple confetti effect view that doesn't use a modifier
struct ConfettiEffectView: View {
    @State private var confetti: [ConfettiPiece] = []
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        ZStack {
            ForEach(confetti) { piece in
                piece.view
                    .position(x: piece.position.x, y: piece.position.y)
                    .opacity(piece.opacity)
                    .rotationEffect(.degrees(piece.rotation))
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        var newConfetti: [ConfettiPiece] = []
        
        // Create 100 pieces of confetti
        for _ in 0..<100 {
            let isCircle = Bool.random()
            let color = colors.randomElement() ?? .yellow
            let size = CGFloat.random(in: 5...15)
            
            let startX = CGFloat.random(in: 0...screenWidth)
            let startY = CGFloat.random(in: -50...0)
            let endY = screenHeight + CGFloat.random(in: 0...100)
            
            let piece = ConfettiPiece(
                isCircle: isCircle,
                color: color,
                size: size,
                position: CGPoint(x: startX, y: startY),
                finalY: endY,
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            
            newConfetti.append(piece)
        }
        
        confetti = newConfetti
        
        // Animate each piece
        for i in 0..<confetti.count {
            let duration = Double.random(in: 1.0...3.0)
            
            // Position animation
            withAnimation(Animation.easeOut(duration: duration)) {
                let piece = confetti[i]
                confetti[i].position.y = piece.finalY
                confetti[i].rotation += Double.random(in: 180...360)
            }
            
            // Fade out animation
            withAnimation(Animation.linear(duration: 0.5).delay(duration * 0.7)) {
                confetti[i].opacity = 0
            }
        }
    }
}

// Simple confetti piece model
struct ConfettiPiece: Identifiable {
    let id = UUID()
    let isCircle: Bool
    let color: Color
    let size: CGFloat
    var position: CGPoint
    let finalY: CGFloat
    var rotation: Double
    var opacity: Double
    
    var view: some View {
        Group {
            if isCircle {
                Circle().fill(color).frame(width: size, height: size)
            } else {
                Rectangle().fill(color).frame(width: size, height: size)
            }
        }
    }
}
