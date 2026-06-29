import Foundation

struct Canal: Codable, Identifiable {
    let id = UUID()
    let nome: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case nome
        case url
    }
}