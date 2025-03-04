# Hebrew Word Adventure - iOS App

A SwiftUI implementation of the Hebrew Word Adventure game that helps users learn Hebrew letters and words in an engaging, game-like format.

## Features

- **Progressive Learning**: Start with 2-letter words and progress to 6-letter words
- **Letter Arrangement**: Arrange scrambled Hebrew letters to form words
- **Visual Feedback**: Immediate feedback on correct/incorrect answers
- **Streak System**: Build streaks for bonus points
- **Bonus Rounds**: Special nikud (vowel) challenges between levels
- **Hint System**: Get help when you're stuck
- **Lives System**: Multiple chances to get the right answer
- **Animations**: Engaging visual effects for correct answers

## Installation

1. Clone this repository
2. Open the project in Xcode 13 or later
3. Build and run on an iOS 15+ device or simulator

## Project Structure

- **App Entry Point**
  - `HebrewLetterGameApp.swift`: The entry point of the application
  
- **Views**
  - `ContentView.swift`: Main container view with game state management
  - `MainGameView.swift`: Primary game interface
  - `BonusRoundView.swift`: Interface for nikud challenges
  - `GameOverView.swift`: End-of-game screen
  - `ConfettiView.swift`: Celebration animations
  
- **Models**
  - `Word.swift`: Word data structure
  - `BonusChallenge.swift`: Bonus challenge data structure
  - `GameState.swift`: Game logic and state management
  
- **Utilities**
  - `GridStack.swift`: Custom grid layout

## Game Flow

1. Start screen introduces the app
2. Players arrange Hebrew letters to form words
3. Correct answers earn points and build streaks
4. After completing all words at a level, a bonus challenge appears
5. Upon completing the bonus round, the next level begins
6. The game ends when all levels are completed or when lives run out

## Customization

You can customize the game by:
- Adding more words to the word banks in `GameState.swift`
- Adjusting the difficulty level
- Adding new nikud challenges
- Changing visual styles and animations

## Credits

This app was converted from a web-based implementation to a native iOS app using SwiftUI.

## License

This project is available for educational purposes.
