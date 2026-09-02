import Foundation

struct Article: Identifiable {
    let id: UUID
    let publication: String
    let author: String
    let date: String
    let title: String
    let content: String
    let aiSummary: String
    let thumbnailURL: URL?
    
    init(id: UUID = UUID(), publication: String, author: String, date: String, title: String, content: String, aiSummary: String, thumbnailURLString: String? = nil) {
        self.id = id
        self.publication = publication
        self.author = author
        self.date = date
        self.title = title
        self.content = content
        self.aiSummary = aiSummary
        if let urlString = thumbnailURLString, !urlString.isEmpty {
            self.thumbnailURL = URL(string: urlString)
        } else {
            self.thumbnailURL = nil
        }
    }
}

