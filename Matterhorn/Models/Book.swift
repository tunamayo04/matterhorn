import Foundation

struct Book: Identifiable, Codable {
    let id: Int
    let fileName: String
    var group: String?
    var cover: URL?
    let data: BookData
}

struct BookData: Codable {
    let title: String
    let styleSheet: String
    let elementHtml: String
}

extension Book {
    static let sampleGroups = ["Favorites", "Japanese Literature", "Classics"]
}
