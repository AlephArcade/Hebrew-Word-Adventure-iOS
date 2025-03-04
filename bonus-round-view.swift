import SwiftUI

struct BonusRoundView: View {
    @ObservedObject var gameState: GameState
    @ObservedObject private var audioManager = AudioManager.shared
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 15/255, green: 20/255, blue: 25/255)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("BONUS ROUND!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.yellow)
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    // Timer
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 4)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(gameState.bonusTimeRemaining) / 10.0)
                            .stroke(Color.yellow, lineWidth: 4)
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(gameState.bonusTimeRemaining)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Time remaining: \(gameState.bonusTimeRemaining) seconds")
                    .onChange(of: gameState.bonusTimeRemaining) {
                        if gameState.bonusTimeRemaining <= 3 && gameState.bonusTimeRemaining > 0 {
                            // Play a ticking sound for last few seconds
                            AudioManager.shared.playButtonTapSound()
                            HapticManager.shared.selection()
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Challenge instructions
                Text("Select the correct pronunciation of this Hebrew letter")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Hebrew letter with nikud
                if let challenge = gameState.currentBonusChallenge {
                    Text(challenge.letter)
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(white: 0.2), Color(white: 0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .cornerRadius(20)
                        )
                        .accessibilityLabel("Hebrew letter with nikud")
                    
                    // Sound info
                    VStack {
                        Text("Sound: \(challenge.sound)")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    .padding()
                    
                    // Options
                    VStack(spacing: 15) {
                        ForEach(challenge.options, id: \.self) { option in
                            Button(action: {
                                handleOptionSelected(option)
                            }) {
                                Text(option)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.blue.opacity(0.6))
                                    )
                            }
                            .accessibilityHint("Select this if you think \(option) is the correct pronunciation")
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Message
                if gameState.showingMessage {
                    Text(gameState.message)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                }
            }
            .padding()
            .onAppear {
                // Play bonus round music when view appears
                AudioManager.shared.playBonusRoundSound()
            }
            .onDisappear {
                // Make sure to clean up any resources when view disappears
                gameState.pauseBonusRoundIfNeeded()
            }
        }
        // Properly support RTL for the entire view
        .environment(\.layoutDirection, .rightToLeft) 
    }
    
    private func handleOptionSelected(_ option: String) {
        // Add haptic and sound feedback
        if let challenge = gameState.currentBonusChallenge, option == challenge.correct {
            HapticManager.shared.success()
            AudioManager.shared.playCorrectAnswerSound()
        } else {
            HapticManager.shared.error()
            AudioManager.shared.playWrongAnswerSound()
        }
        
        // Process the selection
        gameState.handleBonusSelection(selected: option)
    }
}
