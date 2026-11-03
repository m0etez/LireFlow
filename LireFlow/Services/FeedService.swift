import Foundation
import SwiftData

/// Service for fetching and managing RSS feeds
@MainActor
final class FeedService: ObservableObject {

    @Published var isRefreshing = false
    @Published var lastError: Error?

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

        // New parser per fetch: FeedParser keeps parse state, and fetches can overlap.
        return try await FeedParser().parse(data: data)
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
        insertNewArticles(from: parsedFeed, into: feed, in: context)

        feed.lastFetched = Date()
        feed.lastSuccessfulFetch = Date()

        try context.save()

        return feed
    }

    /// Refresh a single feed with new articles
    func refreshFeed(_ feed: Feed, in context: ModelContext) async throws {
        do {
            let parsedFeed = try await fetchFeed(from: feed.url)

            // Update websiteURL if not set (for feeds added before this feature)
            if feed.websiteURL == nil && !parsedFeed.link.isEmpty {
                feed.websiteURL = parsedFeed.link
            }

            insertNewArticles(from: parsedFeed, into: feed, in: context)
            trimArticles(of: feed, keeping: Set(parsedFeed.articles.map(\.url)), in: context)

            // Update health tracking on success
            feed.lastFetched = Date()
            feed.lastSuccessfulFetch = Date()
            feed.lastError = nil
            feed.consecutiveFailures = 0

            try context.save()
        } catch {
            // Update health tracking on failure
            feed.lastFetched = Date()
            feed.consecutiveFailures += 1
            feed.lastError = error.localizedDescription

            try? context.save()
            throw error
        }
    }

    /// Refresh all feeds (sequential to avoid SwiftData concurrency issues)
    func refreshAllFeeds(feeds: [Feed], in context: ModelContext) async {
        guard !isRefreshing else { return }  // auto-refresh and manual refresh can collide
        isRefreshing = true
        lastError = nil

        // Process feeds sequentially - ModelContext is not thread-safe
        for feed in feeds where !feed.isDeleted {
            do {
                try await refreshFeed(feed, in: context)
            } catch {
                lastError = error
                print("Error refreshing feed \(feed.title): \(error)")
            }
        }

        isRefreshing = false
    }

    // MARK: - Article Bookkeeping

    /// Insert parsed articles the feed doesn't have yet. Items older than the cleanup window
    /// are skipped, so "Clean up old articles" doesn't get undone by the next refresh.
    private func insertNewArticles(from parsedFeed: ParsedFeed, into feed: Feed, in context: ModelContext) {
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -ConfigService.shared.config.cleanupOldArticlesDays, to: Date()
        ) ?? .distantPast
        var knownURLs = Set(feed.articles.map(\.url))

        for parsedArticle in parsedFeed.articles
        where parsedArticle.publishedDate >= cutoff && knownURLs.insert(parsedArticle.url).inserted {
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

    /// Enforce "Max Articles per Feed": drop the oldest articles beyond the limit. Articles the
    /// user kept, and ones still listed in the feed (they would just be re-added), stay.
    private func trimArticles(of feed: Feed, keeping currentURLs: Set<String>, in context: ModelContext) {
        let limit = ConfigService.shared.config.maxArticlesPerFeed
        guard feed.articles.count > limit else { return }
        let removable = feed.articles
            .sorted { $0.publishedDate > $1.publishedDate }
            .dropFirst(limit)
            .filter { !$0.isKeptByUser && !currentURLs.contains($0.url) }
        for article in removable {
            context.delete(article)
        }
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
                let href = String(html[range]).replacingOccurrences(of: "&amp;", with: "&")
                // Resolves absolute, root-relative, protocol-relative ("//cdn…") and path-relative hrefs
                return URL(string: href, relativeTo: url)?.absoluteString ?? href
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
