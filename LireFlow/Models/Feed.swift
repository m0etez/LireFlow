import Foundation
import SwiftData

@Model
final class Feed {
    var id: UUID
    var title: String
    var feedDescription: String
    var url: String
    var websiteURL: String?  // The actual website URL (different from feed URL)
    var iconURL: String?
    var lastFetched: Date?
    
    @Relationship(deleteRule: .nullify, inverse: \Folder.feeds)
    var folder: Folder?
    
    @Relationship(deleteRule: .cascade, inverse: \Article.feed)
    var articles: [Article]
    
    init(
        id: UUID = UUID(),
        title: String,
        feedDescription: String = "",
        url: String,
        websiteURL: String? = nil,
        iconURL: String? = nil,
        folder: Folder? = nil
    ) {
        self.id = id
        self.title = title
        self.feedDescription = feedDescription
        self.url = url
        self.websiteURL = websiteURL
        self.iconURL = iconURL
        self.folder = folder
        self.articles = []
        self.lastFetched = nil
    }
    
    var unreadCount: Int {
        articles.filter { !$0.isRead }.count
    }
}

