import SwiftUI

struct MainGameView: View {
    @ObservedObject var gameState: GameState
    @State private var showConfetti = false
    
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
                        .transition(.opacity)
                        .animation(.easeInOut, value: gameState.showingMessage)
                }
            }
            .padding()
        }
        .confetti(isPresented: $showConfetti)
        .onChange(of: gameState.animatingCorrect) { oldValue, newValue in
            if newValue && !oldValue {
                // Trigger confetti when a word is completed correctly
                showConfetti = true
                AudioManager.shared.playCorrectAnswerSound()
                HapticManager.shared.success()
            }
        }
    }
}

// Enhanced Letter Tile View with better animations
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
                    .fill(isSelected ? Color.green : Color(red: 1, green: 0.97, blue: 0.88)) // FFF8E1 in HTML
                    .shadow(radius: 2)
                    .aspectRatio(1, contentMode: .fit)
                
                // Letter text
                Text(letter)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color(red: 0.06, green: 0.08, blue: 0.10)) // 0F1419 in HTML
                
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
            // Correct answer animation - similar to HTML version
            .scaleEffect(animatingCorrect && isSelected ? animationAmount : 1)
            .animation(
                animatingCorrect && isSelected ?
                    Animation.easeInOut(duration: 0.5)
                        .repeatCount(3, autoreverses: true) :
                    nil,
                value: animatingCorrect
            )
            .onChange(of: animatingCorrect) { oldValue, newValue in
                if newValue && !oldValue && isSelected {
                    // Start the pulse animation
                    withAnimation(Animation.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                        animationAmount = 1.1
                    }
                    
                    // Reset the animation after it's done
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        animationAmount = 1.0
                    }
                }
            }
        }
        .disabled(isSelected || animatingCorrect)
    }
}

// Enhanced Answer Slot View with staggered animations
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
        // Use scaleEffect for animation
        .scaleEffect(animationAmount)
        .onChange(of: isCorrect) { oldValue, newValue in
            if newValue && !hasAnimated {
                // Add staggered animation delay based on index
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                    // Start the pulse animation
                    withAnimation(Animation.easeInOut(duration: 0.5).repeatCount(1, autoreverses: true)) {
                        animationAmount = 1.1
                    }
                    
                    // Reset the animation after it's done
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        animationAmount = 1.0
                        hasAnimated = true
                    }
                }
            } else if !newValue {
                hasAnimated = false
            }
        }
    }
}
