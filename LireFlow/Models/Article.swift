import Foundation
import SwiftData

@Model
final class Article {
    var id: UUID
    var title: String
    var summary: String
    var content: String
    var url: String
    var externalURL: String?  // For Reddit: the actual article link
    var author: String?
    var publishedDate: Date
    var isRead: Bool
    var isStarred: Bool
    
    var feed: Feed?
    var readingLists: [ReadingList]?
    
    init(
        id: UUID = UUID(),
        title: String,
        summary: String = "",
        content: String = "",
        url: String,
        author: String? = nil,
        publishedDate: Date = Date(),
        isRead: Bool = false,
        isStarred: Bool = false
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.content = content
        self.url = url
        self.author = author
        self.publishedDate = publishedDate
        self.isRead = isRead
        self.isStarred = isStarred
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: publishedDate, relativeTo: Date())
    }
    
    /// Title with HTML entities decoded
    var displayTitle: String {
        title.decodingHTMLEntities
    }
    
    /// Summary with HTML stripped and entities decoded
    var plainTextSummary: String {
        summary.strippingHTML.decodingHTMLEntities
    }
    
    /// Best URL for fetching full article (prefers external URL for Reddit)
    var articleURL: String {
        externalURL ?? url
    }
}

