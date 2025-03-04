import SwiftUI

struct SettingsView: View {
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var dataManager = GameDataManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingResetConfirmation = false
    @State private var showingLogViewer = false
    
    // Use proper initialization with defaults from UserDefaults
    @AppStorage("haptics_enabled") private var hapticsEnabled = UserDefaults.standard.bool(forKey: "haptics_enabled")
    @AppStorage("continue_enabled") private var continueEnabled = UserDefaults.standard.bool(forKey: "continue_enabled")
    @AppStorage("logging_enabled") private var loggingEnabled = UserDefaults.standard.bool(forKey: "logging_enabled")
    @AppStorage("log_to_file") private var logToFile = UserDefaults.standard.bool(forKey: "log_to_file")
    
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
                    .accessibilityHint("Toggle sound effects on or off")
                    
                    // Volume slider
                    if !audioManager.isMuted {
                        HStack {
                            Image(systemName: "speaker")
                                .foregroundColor(.gray)
                                .accessibility(hidden: true)
                            
                            Slider(value: $audioManager.volume, in: 0...1) { _ in
                                if !audioManager.isMuted {
                                    AudioManager.shared.playButtonTapSound()
                                }
                            }
                            .accessibilityLabel("Volume level")
                            .accessibilityValue("\(Int(audioManager.volume * 100))%")
                            
                            Image(systemName: "speaker.wave.3")
                                .foregroundColor(.gray)
                                .accessibility(hidden: true)
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
                    .accessibilityHint("Toggle vibration feedback when playing")
                }
                
                // Game settings
                Section(header: Text("GAME")) {
                    // Continue last game
                    Toggle(isOn: $continueEnabled) {
                        Label("Continue Last Game", systemImage: "arrow.clockwise")
                    }
                    .accessibilityHint("Enable or disable the continue game option")
                    
                    // Show high scores
                    NavigationLink(destination: HighScoresView()) {
                        Label("High Scores", systemImage: "trophy")
                    }
                    .accessibilityHint("View your high scores")
                    
                    // Reset progress
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        Label("Reset All Progress", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    .accessibilityHint("Delete all your progress, high scores, and learned words")
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
                    .accessibilityHint("Enable or disable debug logging")
                    
                    if loggingEnabled {
                        Toggle(isOn: $logToFile) {
                            Label("Log to File", systemImage: "folder")
                        }
                        .accessibilityHint("Save logs to a file that can be viewed later")
                        
                        Button(action: {
                            showingLogViewer = true
                        }) {
                            Label("View Logs", systemImage: "list.bullet")
                        }
                        .accessibilityHint("View debug logs")
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
                AudioManager.shared.playButtonTapSound()
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
        // Apply consistent RTL for Hebrew content
        .environment(\.layoutDirection, .rightToLeft)
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
        .accessibilityElement(children: .combine)
        .accessibility(label: Text("\(title): \(value)"))
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
                    .accessibility(label: Text("No high scores recorded yet"))
            } else {
                ForEach(dataManager.highScores.indices, id: \.self) { index in
                    let score = dataManager.highScores[index]
                    HStack {
                        // Rank
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(index < 3 ? .yellow : .gray)
                            .frame(width: 30)
                            .accessibility(label: Text("Rank \(index + 1)"))
                        
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
                    .accessibilityElement(children: .combine)
                    .accessibility(label: Text("\(score.playerName.isEmpty ? "Player" : score.playerName): \(score.score) points, Level \(score.level), \(score.wordsCompleted) words"))
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
                .accessibilityLabel(Text("Application logs"))
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
