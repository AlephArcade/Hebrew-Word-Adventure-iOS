import SwiftUI

struct SettingsView: View {
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var dataManager = GameDataManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingResetConfirmation = false
    @State private var showingLogViewer = false
    
    // Settings state variables
    @AppStorage("haptics_enabled") private var hapticsEnabled = true
    @AppStorage("continue_enabled") private var continueEnabled = true
    @AppStorage("logging_enabled") private var loggingEnabled = false
    @AppStorage("log_to_file") private var logToFile = false
    
    var body: some View {
        NavigationView {
            Form {
                // Sound settings
                Section(header: Text("SOUND")) {
                    // Sound toggle
                    Toggle(isOn: Binding(
                        get: { !audioManager.isMuted },
                        set: { audioManager.isMuted = !$0 }
                    )) {
                        Label("Sound Effects", systemImage: "speaker.wave.2")
                    }
                    .onChange(of: audioManager.isMuted) { _ in
                        if !audioManager.isMuted {
                            AudioManager.shared.playButtonTapSound()
                        }
                    }
                    
                    // Volume slider
                    if !audioManager.isMuted {
                        HStack {
                            Image(systemName: "speaker")
                                .foregroundColor(.gray)
                            
                            Slider(value: $audioManager.volume, in: 0...1) { _ in
                                if !audioManager.isMuted {
                                    AudioManager.shared.playButtonTapSound()
                                }
                            }
                            
                            Image(systemName: "speaker.wave.3")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Haptic feedback settings
                Section(header: Text("HAPTICS")) {
                    Toggle(isOn: $hapticsEnabled) {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    .onChange(of: hapticsEnabled) { newValue in
                        if newValue {
                            HapticManager.shared.mediumImpact()
                        }
                    }
                }
                
                // Game settings
                Section(header: Text("GAME")) {
                    // Continue last game
                    Toggle(isOn: $continueEnabled) {
                        Label("Continue Last Game", systemImage: "arrow.clockwise")
                    }
                    
                    // Show high scores
                    NavigationLink(destination: HighScoresView()) {
                        Label("High Scores", systemImage: "trophy")
                    }
                    
                    // Reset progress
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        Label("Reset All Progress", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
                
                // Game statistics
                Section(header: Text("STATISTICS")) {
                    GameStatisticsView(statistics: dataManager.statistics)
                }
                
                // Advanced settings
                Section(header: Text("ADVANCED")) {
                    // Debug logging
                    Toggle(isOn: $loggingEnabled) {
                        Label("Enable Logging", systemImage: "doc.text")
                    }
                    
                    if loggingEnabled {
                        Toggle(isOn: $logToFile) {
                            Label("Log to File", systemImage: "folder")
                        }
                        
                        Button(action: {
                            showingLogViewer = true
                        }) {
                            Label("View Logs", systemImage: "list.bullet")
                        }
                    }
                }
                
                // App info
                Section(header: Text("ABOUT")) {
                    VStack(alignment: .center, spacing: 10) {
                        Text("Hebrew Word Adventure")
                            .font(.headline)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("© 2023 The Hebrew Word Adventure Team")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingResetConfirmation) {
                Alert(
                    title: Text("Reset Progress"),
                    message: Text("This will reset all your progress, scores, and learned words. This cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        resetAllProgress()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingLogViewer) {
                LogViewerView()
            }
        }
    }
    
    private func resetAllProgress() {
        // Clear high scores
        dataManager.highScores = []
        
        // Clear learned words
        dataManager.learnedWords = []
        
        // Clear saved game state
        dataManager.clearSavedGameState()
        
        // Reset statistics
        dataManager.resetStatistics()
        
        // Save changes
        dataManager.saveData()
        
        // Haptic feedback
        HapticManager.shared.heavyImpact()
    }
}

struct GameStatisticsView: View {
    let statistics: GameStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statRow(title: "Games Played", value: "\(statistics.gamesPlayed)")
            statRow(title: "Highest Score", value: "\(statistics.highestScore)")
            statRow(title: "Average Score", value: "\(statistics.averageScore)")
            statRow(title: "Highest Level", value: "\(statistics.highestLevel)")
            statRow(title: "Words Learned", value: "\(statistics.totalWordsLearned)")
            statRow(title: "Hints Used", value: "\(statistics.hintsUsed)")
            statRow(title: "Bonus Rounds", value: "\(statistics.bonusRoundsCompleted)/\(statistics.bonusRoundsPlayed)")
            
            if statistics.gamesPlayed > 0 {
                statRow(title: "Avg. Game Time", value: formatTime(statistics.averageGameTime))
                statRow(title: "Total Play Time", value: formatTime(statistics.totalPlayTime))
            }
        }
        .padding(.vertical, 5)
    }
    
    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct HighScoresView: View {
    @ObservedObject var dataManager = GameDataManager.shared
    
    var body: some View {
        List {
            if dataManager.highScores.isEmpty {
                Text("No high scores yet")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(dataManager.highScores.indices, id: \.self) { index in
                    let score = dataManager.highScores[index]
                    HStack {
                        // Rank
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(index < 3 ? .yellow : .gray)
                            .frame(width: 30)
                        
                        // Name
                        Text(score.playerName.isEmpty ? "Player" : score.playerName)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        // Score
                        VStack(alignment: .trailing) {
                            Text("\(score.score)")
                                .font(.headline)
                            
                            Text("Level \(score.level) • \(score.wordsCompleted) words")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("High Scores")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LogViewerView: View {
    @State private var logContents = Logger.shared.getLogContents()
    @State private var showingClearConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    Text(logContents)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("App Logs")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Clear") {
                    showingClearConfirmation = true
                }
                .foregroundColor(.red)
            )
            .alert(isPresented: $showingClearConfirmation) {
                Alert(
                    title: Text("Clear Logs"),
                    message: Text("Are you sure you want to clear all logs?"),
                    primaryButton: .destructive(Text("Clear")) {
                        Logger.shared.clearLog()
                        logContents = "Logs cleared"
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
            