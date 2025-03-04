import Foundation

struct BonusChallenge: Identifiable {
    let id = UUID()
    let letter: String
    let options: [String]
    let correct: String
    let sound: String
    let transliteration: String
}

struct BonusReward {
    var extraHints: Int
    var scoreMultiplier: Double
}
