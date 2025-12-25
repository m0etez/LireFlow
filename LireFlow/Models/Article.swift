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

    /// Estimated reading time in minutes (based on 200 words per minute)
    var readingTimeMinutes: Int {
        let text = content.isEmpty ? summary : content
        let strippedText = text.strippingHTML
        let wordCount = strippedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        let minutes = max(1, wordCount / 200) // Minimum 1 minute
        return minutes
    }

    /// Formatted reading time string (e.g., "5 min read")
    var readingTimeText: String {
        "\(readingTimeMinutes) min read"
    }
}

