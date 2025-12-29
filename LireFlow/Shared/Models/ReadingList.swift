import Foundation
import SwiftData

@Model
final class ReadingList {
    var id: UUID
    var name: String
    var icon: String
    var createdAt: Date
    
    @Relationship(inverse: \Article.readingLists)
    var articles: [Article]
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "bookmark",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
        self.articles = []
    }
    
    var articleCount: Int {
        articles.count
    }
}
