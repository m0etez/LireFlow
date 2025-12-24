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
    var lastSuccessfulFetch: Date?
    var lastError: String?
    var consecutiveFailures: Int

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
        self.lastSuccessfulFetch = nil
        self.lastError = nil
        self.consecutiveFailures = 0
    }
    
    var unreadCount: Int {
        articles.filter { !$0.isRead }.count
    }

    var isHealthy: Bool {
        consecutiveFailures < 3
    }

    var healthStatus: String {
        if let error = lastError, !isHealthy {
            return "Error: \(error)"
        } else if let lastSuccess = lastSuccessfulFetch {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Updated \(formatter.localizedString(for: lastSuccess, relativeTo: Date()))"
        } else {
            return "Never updated"
        }
    }
}

