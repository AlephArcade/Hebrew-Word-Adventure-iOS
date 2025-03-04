import SwiftUI

struct DictionaryView: View {
    @ObservedObject var dataManager = GameDataManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: Int? = nil
    @State private var selectedWord: Word? = nil
    @State private var showingWordDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search words", text: $searchText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Level filter buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: {
                            selectedLevel = nil
                        }) {
                            Text("All")
                                .font(.subheadline)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(selectedLevel == nil ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(selectedLevel == nil ? .white : .primary)
                                .cornerRadius(15)
                        }
                        
                        ForEach(1...6, id: \.self) { level in
                            Button(action: {
                                selectedLevel = level
                            }) {
                                Text("Level \(level)")
                                    .font(.subheadline)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(selectedLevel == level ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(selectedLevel == level ? .white : .primary)
                                    .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Word count
                let filteredWords = dataManager.getLearnedWords(filterLevel: selectedLevel, searchTerm: searchText)
                Text("\(filteredWords.count) words")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Words list
                if filteredWords.isEmpty {
                    emptyStateView
                } else {
                    wordsList(words: filteredWords)
                }
            }
            .navigationTitle("Hebrew Dictionary")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingWordDetail) {
                if let word = selectedWord {
                    WordDetailView(word: word)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            if dataManager.learnedWords.isEmpty {
                Text("Your dictionary is empty")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("Complete words in the game to add them to your dictionary")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("No matching words")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("Try changing your search or filter")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func wordsList(words: [Word]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            ForEach(words) { word in
                WordCardView(word: word)
                    .onTapGesture {
                        HapticManager.shared.selection()
                        selectedWord = word
                        showingWordDetail = true
                    }
            }
        }
        .padding()
    }
}

struct WordCardView: View {
    let word: Word
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(word.hebrew)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            Text(word.transliteration)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(word.meaning)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .frame(minHeight: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct WordDetailView: View {
    let word: Word
    @State private var showingTransliteration = true
    @State private var isPronouncing = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 30) {
            // Close button
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Hebrew word
            Text(word.hebrew)
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(.primary)
                .padding()
                .animation(.easeInOut, value: showingTransliteration)
            
            // Meaning
            Text(word.meaning)
                .font(.title3)
                .foregroundColor(.secondary)
                .padding()
            
            // Transliteration with toggle
            VStack {
                Button(action: {
                    withAnimation {
                        showingTransliteration.toggle()
                    }
                }) {
                    HStack {
                        Text("Transliteration")
                            .font(.headline)
                        
                        Image(systemName: showingTransliteration ? "chevron.up" : "chevron.down")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
                
                if showingTransliteration {
                    Text(word.transliteration)
                        .font(.title2)
                        .italic()
                        .padding()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            
            // Pronunciation button
            Button(action: {
                HapticManager.shared.mediumImpact()
                isPronouncing = true
                
                // Here you would integrate with a pronunciation service
                // For now, we'll just simulate the effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isPronouncing = false
                }
            }) {
                HStack {
                    Image(systemName: isPronouncing ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.title2)
                    
                    Text(isPronouncing ? "Playing..." : "Pronounce")
                        .font(.headline)
                }
                .padding()
                .frame(width: 200)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 3)
            }
            .disabled(isPronouncing)
            
            Spacer()
            
            // Letter-by-letter breakdown (for a future enhancement)
            // This section could show each letter of the word with its own meaning
            
            Spacer()
        }
        .padding()
    }
}

// Preview
struct DictionaryView_Previews: PreviewProvider {
    static var previews: some View {
        DictionaryView()
    }
}
