import Foundation

struct Word: Identifiable {
    let id = UUID()
    let hebrew: String
    let transliteration: String
    let meaning: String
}
