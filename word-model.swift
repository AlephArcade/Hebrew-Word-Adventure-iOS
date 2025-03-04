import Foundation

struct Word: Identifiable, Codable {
    let id: UUID
    let hebrew: String
    let transliteration: String
    let meaning: String
    
    init(id: UUID = UUID(), hebrew: String, transliteration: String, meaning: String) {
        self.id = id
        self.hebrew = hebrew
        self.transliteration = transliteration
        self.meaning = meaning
    }
}
