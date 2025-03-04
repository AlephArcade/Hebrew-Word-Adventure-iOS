// HEBREW WORD ADVENTURE - ASSETS GUIDE

/*
 This file provides guidance on setting up the Assets.xcassets folder for your app.
 You'll need to add these assets in Xcode manually.
 
 1. In Xcode, select Assets.xcassets in the Project Navigator.
 2. Create new asset categories as described below.
*/

// APP ICON
/*
 Create an AppIcon set within Assets.xcassets.
 You'll need multiple sizes:
 - 20pt, 29pt, 40pt, 60pt for iPhone
 - 20pt, 29pt, 40pt, 76pt, 83.5pt for iPad
 
 Design a simple icon that represents Hebrew letters or words, 
 perhaps using colorful Hebrew letter blocks or a stylized aleph.
*/

// COLORS
/*
 Create a "Colors" folder in Assets.xcassets and add these color assets:
 
 1. backgroundColor
    - Dark mode: RGB(15, 20, 25)
    - Light mode: RGB(240, 242, 245)
    
 2. accentColor
    - Both modes: RGB(255, 215, 0) (Gold)
    
 3. correctColor
    - Both modes: RGB(76, 175, 80) (Green)
    
 4. incorrectColor
    - Both modes: RGB(244, 67, 54) (Red)
    
 5. tileColor
    - Dark mode: RGB(255, 248, 225)
    - Light mode: RGB(255, 248, 225)
    
 6. textPrimaryColor
    - Dark mode: RGB(255, 255, 255)
    - Light mode: RGB(10, 10, 10)
    
 7. textSecondaryColor
    - Dark mode: RGB(170, 170, 170)
    - Light mode: RGB(100, 100, 100)
*/

// SOUNDS
/*
 Add these sound files to your project:
 
 1. correct_answer.mp3 - A positive, celebratory sound
 2. wrong_answer.mp3 - A subtle negative feedback sound
 3. hint_used.mp3 - A subtle "lightbulb" sound
 4. level_up.mp3 - An uplifting achievement sound
 5. bonus_round.mp3 - An exciting, anticipatory sound
 6. game_over.mp3 - An end-of-game sound
 7. game_complete.mp3 - A triumphant victory sound
 
 You can find free sound effects on websites like freesound.org
 or create your own using GarageBand.
 
 To use these sounds in the app, add this code to load and play them:
*/

import AVFoundation

func playSound(named soundName: String) {
    guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
        print("Could not find sound file: \(soundName)")
        return
    }
    
    do {
        let player = try AVAudioPlayer(contentsOf: soundURL)
        player.prepareToPlay()
        player.play()
    } catch {
        print("Error playing sound: \(error.localizedDescription)")
    }
}

// Example usage in the GameState model:
// playSound(named: "correct_answer")

// FONTS
/*
 For better Hebrew character display, consider adding a custom Hebrew font:
 
 1. Download a Hebrew font like:
    - Open Sans Hebrew
    - Alef Hebrew
    - Noto Sans Hebrew
   
 2. Add the font file (.ttf or .otf) to your project
 
 3. Add the font to your Info.plist by adding a key:
    "Fonts provided by application" (UIAppFonts) and include the filename
    
 4. Use the font in your SwiftUI views:
*/

// Example usage:
// Text("שָׁלוֹם")
//    .font(.custom("OpenSansHebrew-Bold", size: 32))

// ACCESSIBILITY
/*
 Remember to consider accessibility:
 
 1. Add meaningful accessibility labels to your UI elements
 2. Ensure color contrast meets WCAG guidelines
 3. Support Dynamic Type for text scaling
 4. Include VoiceOver support for important game actions
*/
