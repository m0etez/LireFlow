import Foundation
import SwiftData

/// Service for fetching and managing RSS feeds
@MainActor
final class FeedService: ObservableObject {
    
    @Published var isRefreshing = false
    @Published var lastError: Error?
    
    private let parser = FeedParser()
    
    // MARK: - Feed Fetching
    
    /// Fetch a single feed by URL and return parsed data
    func fetchFeed(from urlString: String) async throws -> ParsedFeed {
        guard let url = URL(string: urlString) else {
            throw FeedServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FeedServiceError.invalidResponse
        }
        
        return try await parser.parse(data: data)
    }
    
    /// Add a new feed to the database
    func addFeed(url: String, to folder: Folder? = nil, in context: ModelContext) async throws -> Feed {
        let parsedFeed = try await fetchFeed(from: url)
        
        let feed = Feed(
            title: parsedFeed.title,
            feedDescription: parsedFeed.description,
            url: url,
            websiteURL: parsedFeed.link.isEmpty ? nil : parsedFeed.link,
            folder: folder
        )
        
        context.insert(feed)
        
        // Add articles
        for parsedArticle in parsedFeed.articles {
            let article = Article(
                title: parsedArticle.title,
                summary: parsedArticle.summary,
                content: parsedArticle.content,
                url: parsedArticle.url,
                author: parsedArticle.author,
                publishedDate: parsedArticle.publishedDate
            )
            article.externalURL = parsedArticle.externalURL
            article.feed = feed
            feed.articles.append(article)
            context.insert(article)
        }
        
        feed.lastFetched = Date()
        
        try context.save()
        
        return feed
    }
    
    /// Refresh a single feed with new articles
    func refreshFeed(_ feed: Feed, in context: ModelContext) async throws {
        let parsedFeed = try await fetchFeed(from: feed.url)
        
        // Update websiteURL if not set (for feeds added before this feature)
        if feed.websiteURL == nil && !parsedFeed.link.isEmpty {
            feed.websiteURL = parsedFeed.link
        }
        
        // Get existing article URLs for deduplication
        let existingURLs = Set(feed.articles.map { $0.url })
        
        // Add only new articles
        for parsedArticle in parsedFeed.articles {
            if !existingURLs.contains(parsedArticle.url) {
                let article = Article(
                    title: parsedArticle.title,
                    summary: parsedArticle.summary,
                    content: parsedArticle.content,
                    url: parsedArticle.url,
                    author: parsedArticle.author,
                    publishedDate: parsedArticle.publishedDate
                )
                article.externalURL = parsedArticle.externalURL
                article.feed = feed
                feed.articles.append(article)
                context.insert(article)
            }
        }
        
        feed.lastFetched = Date()
        try context.save()
    }
    
    /// Refresh all feeds (sequential to avoid SwiftData concurrency issues)
    func refreshAllFeeds(feeds: [Feed], in context: ModelContext) async {
        isRefreshing = true
        lastError = nil
        
        // Process feeds sequentially - ModelContext is not thread-safe
        for feed in feeds {
            do {
                try await refreshFeed(feed, in: context)
            } catch {
                lastError = error
                print("Error refreshing feed \(feed.title): \(error)")
            }
        }
        
        isRefreshing = false
    }
    
    /// Delete a feed and all its articles
    func deleteFeed(_ feed: Feed, in context: ModelContext) {
        context.delete(feed)
        try? context.save()
    }
    
    // MARK: - Feed Discovery
    
    /// Try to discover feed URL from a website URL
    func discoverFeed(from websiteURL: String) async throws -> String? {
        guard let url = URL(string: websiteURL) else {
            throw FeedServiceError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let html = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Look for RSS/Atom link tags
        let patterns = [
            #"<link[^>]*type=[\"']application/rss\+xml[\"'][^>]*href=[\"']([^\"']+)[\"']"#,
            #"<link[^>]*href=[\"']([^\"']+)[\"'][^>]*type=[\"']application/rss\+xml[\"']"#,
            #"<link[^>]*type=[\"']application/atom\+xml[\"'][^>]*href=[\"']([^\"']+)[\"']"#,
            #"<link[^>]*href=[\"']([^\"']+)[\"'][^>]*type=[\"']application/atom\+xml[\"']"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                var feedURL = String(html[range])
                
                // Handle relative URLs
                if feedURL.hasPrefix("/") {
                    if let baseURL = URL(string: websiteURL) {
                        feedURL = "\(baseURL.scheme ?? "https")://\(baseURL.host ?? "")\(feedURL)"
                    }
                }
                
                return feedURL
            }
        }
        
        // Try common feed paths
        let commonPaths = ["/feed", "/rss", "/feed.xml", "/rss.xml", "/atom.xml", "/index.xml"]
        for path in commonPaths {
            let potentialURL = websiteURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + path
            if let _ = try? await fetchFeed(from: potentialURL) {
                return potentialURL
            }
        }
        
        return nil
    }
}

// MARK: - Errors

enum FeedServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case feedNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .feedNotFound:
            return "No RSS feed was found at this URL."
        }
    }
}
