import Foundation

struct Book: Identifiable, Codable {
    let id: Int
    var title: String
    let fileName: String      // file inside Documents/Books
    var group: String?
}

extension Book {
    // Fake group list for now
    static let sampleGroups = ["Favorites", "Japanese Literature", "Classics"]
}
