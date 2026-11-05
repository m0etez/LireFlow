import Foundation
import SwiftData

/// Service for fetching and managing RSS feeds
@MainActor
final class FeedService: ObservableObject {

    @Published var isRefreshing = false
    @Published var lastError: Error?

    // MARK: - Feed Fetching

    enum FetchOutcome {
        case notModified
        case feed(ParsedFeed, etag: String?, lastModified: String?)
    }

    /// Download and parse a feed, off the main actor. With validators from the last fetch,
    /// an unchanged feed answers 304 and nothing is downloaded or parsed.
    nonisolated static func fetch(_ urlString: String, etag: String? = nil, lastModified: String? = nil) async throws -> FetchOutcome {
        guard let url = URL(string: urlString) else {
            throw FeedServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        // Validators are handled here: URLCache would otherwise turn a 304 back into a 200
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let etag { request.setValue(etag, forHTTPHeaderField: "If-None-Match") }
        if let lastModified { request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since") }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FeedServiceError.invalidResponse
        }
        switch http.statusCode {
        case 304:
            return .notModified
        case 429:
            throw FeedServiceError.rateLimited
        case 200...299:
            // New parser per fetch: FeedParser keeps parse state, and fetches can overlap.
            let parsed = try await FeedParser().parse(data: data)
            return .feed(parsed, etag: http.value(forHTTPHeaderField: "ETag"),
                         lastModified: http.value(forHTTPHeaderField: "Last-Modified"))
        default:
            throw FeedServiceError.invalidResponse
        }
    }

    /// Fetch a single feed by URL and return parsed data
    func fetchFeed(from urlString: String) async throws -> ParsedFeed {
        guard case .feed(let parsed, _, _) = try await Self.fetch(urlString) else {
            throw FeedServiceError.invalidResponse
        }
        return parsed
    }

    /// Add a new feed to the database
    func addFeed(url: String, to folder: Folder? = nil, in context: ModelContext) async throws -> Feed {
        let parsedFeed = try await fetchFeed(from: url)

        let feed = Feed(
            title: parsedFeed.title.isEmpty ? Self.fallbackTitle(for: parsedFeed.link.isEmpty ? url : parsedFeed.link) : parsedFeed.title,
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

    struct BulkAddResult {
        var failedURLs: [String] = []
        var limitSkipped = 0
    }

    /// Add several feeds (catalog, onboarding): skips ones already subscribed, stops at the
    /// free tier limit, and keeps going when a single feed fails.
    func addFeeds(urls: [String], to folder: Folder? = nil, in context: ModelContext) async -> BulkAddResult {
        var result = BulkAddResult()
        var knownURLs = Set(((try? context.fetch(FetchDescriptor<Feed>())) ?? []).map(\.url))

        for url in urls where !knownURLs.contains(url) {
            guard StoreService.shared.canAddFeed(currentCount: knownURLs.count) else {
                result.limitSkipped += 1
                continue
            }
            do {
                _ = try await addFeed(url: url, to: folder, in: context)
                knownURLs.insert(url)
            } catch {
                result.failedURLs.append(url)
            }
        }
        return result
    }

    /// Refresh a single feed with new articles
    func refreshFeed(_ feed: Feed, in context: ModelContext) async throws {
        followMove(of: feed)
        let result: Result<FetchOutcome, Error>
        do {
            result = .success(try await Self.fetch(feed.url, etag: feed.etag, lastModified: feed.lastModified))
        } catch {
            result = .failure(error)
        }
        try apply(result, to: feed, in: context)
    }

    /// Refresh all feeds: several sites at once, one request at a time per site (many sites
    /// rate-limit bursts). Only fetching and parsing run concurrently, off the main
    /// actor; results are saved here one by one, since ModelContext isn't thread-safe.
    func refreshAllFeeds(feeds: [Feed], in context: ModelContext) async {
        guard !isRefreshing else { return }  // auto-refresh and manual refresh can collide
        isRefreshing = true
        lastError = nil

        let live = feeds.filter { !$0.isDeleted }
        live.forEach(followMove)
        let jobsBySite = Dictionary(grouping: live.indices) { URL(string: live[$0].url)?.host() ?? "" }
            .values.map { indices in
                indices.map { FetchJob(index: $0, url: live[$0].url, etag: live[$0].etag, lastModified: live[$0].lastModified) }
            }

        await withTaskGroup(of: [(Int, Result<FetchOutcome, Error>)].self) { group in
            var pending = jobsBySite.makeIterator()
            for _ in 0..<6 {
                if let jobs = pending.next() { group.addTask { await Self.fetchInOrder(jobs) } }
            }
            for await results in group {
                for (index, result) in results where !live[index].isDeleted {
                    do {
                        try apply(result, to: live[index], in: context)
                    } catch {
                        lastError = error
                    }
                }
                if let jobs = pending.next() { group.addTask { await Self.fetchInOrder(jobs) } }
            }
        }

        Self.autoMarkRead(in: context)
        isRefreshing = false
    }

    private struct FetchJob {
        let index: Int
        let url: String
        let etag: String?
        let lastModified: String?
    }

    /// One site's feeds, one after another with a short pause between them
    private nonisolated static func fetchInOrder(_ jobs: [FetchJob]) async -> [(Int, Result<FetchOutcome, Error>)] {
        var results: [(Int, Result<FetchOutcome, Error>)] = []
        for (position, job) in jobs.enumerated() {
            if position > 0 {
                try? await Task.sleep(for: .seconds(1))
            }
            do {
                results.append((job.index, .success(try await fetch(job.url, etag: job.etag, lastModified: job.lastModified))))
            } catch FeedServiceError.rateLimited {
                // The rest of this site would be refused too: leave them for the next refresh
                results += jobs[position...].map { ($0.index, .failure(FeedServiceError.rateLimited)) }
                break
            } catch {
                results.append((job.index, .failure(error)))
            }
        }
        return results
    }

    /// Catalog feeds whose publisher moved them switch to the new URL
    private func followMove(of feed: Feed) {
        guard let moved = DefaultFeeds.movedURLs[feed.url] else { return }
        feed.url = moved
        feed.etag = nil
        feed.lastModified = nil
    }

    /// Save one fetch result: new articles, validators and health. Rethrows fetch errors.
    private func apply(_ result: Result<FetchOutcome, Error>, to feed: Feed, in context: ModelContext) throws {
        feed.lastFetched = Date()
        switch result {
        case .success(let outcome):
            if case .feed(let parsedFeed, let etag, let lastModified) = outcome {
                if feed.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    feed.title = parsedFeed.title
                }
                // Update websiteURL if not set (for feeds added before this feature)
                if feed.websiteURL == nil && !parsedFeed.link.isEmpty {
                    feed.websiteURL = parsedFeed.link
                }
                insertNewArticles(from: parsedFeed, into: feed, in: context)
                trimArticles(of: feed, keeping: Set(parsedFeed.articles.map(\.url)), in: context)
                feed.etag = etag
                feed.lastModified = lastModified
            }
            feed.lastSuccessfulFetch = Date()
            feed.lastError = nil
            feed.consecutiveFailures = 0
        case .failure(let error):
            feed.lastError = error.localizedDescription
            // Rate limiting passes: it doesn't count toward marking the feed broken
            if (error as? FeedServiceError) != .rateLimited {
                feed.consecutiveFailures += 1
            }
        }

        // Feeds saved without a name (empty <title>, OPML text="") get one back
        if feed.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            feed.title = Self.fallbackTitle(for: feed.websiteURL ?? feed.url)
        }

        if case .failure(let error) = result {
            try? context.save()
            throw error
        }
        try context.save()
    }

    /// "Mark as read after N days": old unread articles stop piling up
    static func autoMarkRead(in context: ModelContext) {
        let days = ConfigService.shared.config.autoMarkReadDays
        guard days > 0, let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return }
        let stale = FetchDescriptor<Article>(predicate: #Predicate { !$0.isRead && $0.publishedDate < cutoff })
        markRead((try? context.fetch(stale)) ?? [], in: context)
    }

    /// A broken feed's site may advertise a new feed URL: switch to it if it works.
    /// Returns a message for the user.
    func findNewURL(for feed: Feed, in context: ModelContext) async -> String {
        guard let site = URL(string: feed.websiteURL ?? feed.url),
              let host = site.host(),
              let found = try? await discoverFeed(from: "\(site.scheme ?? "https")://\(host)"),
              found != feed.url,
              (try? await fetchFeed(from: found)) != nil else {
            return String(localized: "No other feed was found on this site.")
        }
        let subscribed = ((try? context.fetch(FetchDescriptor<Feed>())) ?? []).contains { $0.url == found }
        guard !subscribed else {
            return String(localized: "You already follow this site’s current feed (\(found)).")
        }
        feed.url = found
        feed.etag = nil
        feed.lastModified = nil
        feed.consecutiveFailures = 0
        try? await refreshFeed(feed, in: context)
        return String(localized: "Feed updated to \(found).")
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

    /// A readable name from a URL's host ("www.lemonde.fr" → "lemonde.fr"), for feeds without a title
    nonisolated static func fallbackTitle(for urlString: String) -> String {
        guard let host = URL(string: urlString)?.host() else { return urlString }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
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
    case alreadySubscribed
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return String(localized: "The site is limiting requests. LireFlow will try again at the next refresh.")
        case .invalidURL:
            return String(localized: "Enter a web address, like example.com/feed.")
        case .invalidResponse:
            return String(localized: "The site didn’t return a feed.")
        case .feedNotFound:
            return String(localized: "No RSS feed was found at this URL.")
        case .alreadySubscribed:
            return String(localized: "You’re already subscribed to this feed.")
        }
    }
}
