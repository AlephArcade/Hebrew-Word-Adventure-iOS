import Foundation

struct Word: Identifiable, Codable {
    let id = UUID()
    let hebrew: String
    let transliteration: String
    let meaning: String
}
