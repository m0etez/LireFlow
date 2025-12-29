import Foundation

/// Parsed feed data before saving to SwiftData
struct ParsedFeed {
    var title: String
    var description: String
    var link: String
    var articles: [ParsedArticle]
}

/// Parsed article data before saving to SwiftData
struct ParsedArticle {
    var title: String
    var summary: String
    var content: String
    var url: String
    var externalURL: String?  // For Reddit: the actual article link
    var author: String?
    var publishedDate: Date
}

/// RSS and Atom feed parser using XMLParser
final class FeedParser: NSObject, XMLParserDelegate {
    
    enum FeedType {
        case rss
        case atom
        case unknown
    }
    
    private var feedType: FeedType = .unknown
    private var currentElement = ""
    private var currentText = ""
    
    // Feed-level data
    private var feedTitle = ""
    private var feedDescription = ""
    private var feedLink = ""
    
    // Article-level data
    private var articles: [ParsedArticle] = []
    private var currentArticle: ParsedArticle?
    private var isInsideItem = false
    private var isInsideEntry = false
    
    // MARK: - Public API
    
    func parse(data: Data) async throws -> ParsedFeed {
        return try await withCheckedThrowingContinuation { continuation in
            let parser = XMLParser(data: data)
            parser.delegate = self
            
            if parser.parse() {
                let feed = ParsedFeed(
                    title: feedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: feedDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    link: feedLink.trimmingCharacters(in: .whitespacesAndNewlines),
                    articles: articles
                )
                continuation.resume(returning: feed)
            } else if let error = parser.parserError {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(throwing: FeedParserError.unknownError)
            }
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parserDidStartDocument(_ parser: XMLParser) {
        feedType = .unknown
        currentElement = ""
        currentText = ""
        feedTitle = ""
        feedDescription = ""
        feedLink = ""
        articles = []
        currentArticle = nil
        isInsideItem = false
        isInsideEntry = false
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName.lowercased()
        currentText = ""
        
        switch currentElement {
        case "rss", "rdf:rdf":
            feedType = .rss
        case "feed":
            feedType = .atom
        case "item":
            isInsideItem = true
            currentArticle = ParsedArticle(title: "", summary: "", content: "", url: "", publishedDate: Date())
        case "entry":
            isInsideEntry = true
            currentArticle = ParsedArticle(title: "", summary: "", content: "", url: "", publishedDate: Date())
        case "link":
            // Handle Atom link elements
            if feedType == .atom {
                if let href = attributeDict["href"] {
                    let rel = attributeDict["rel"] ?? "alternate"
                    if isInsideEntry {
                        if rel == "alternate" || rel.isEmpty {
                            currentArticle?.url = href
                        }
                    } else {
                        if rel == "alternate" || rel.isEmpty {
                            feedLink = href
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let cdataString = String(data: CDATABlock, encoding: .utf8) {
            currentText += cdataString
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let element = elementName.lowercased()
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isInsideItem || isInsideEntry {
            // Parsing article
            switch element {
            case "title":
                currentArticle?.title = text
            case "description", "summary":
                currentArticle?.summary = text
            case "content", "content:encoded":
                currentArticle?.content = text
                // For Reddit: extract external link from content
                if let externalLink = extractExternalLink(from: text) {
                    currentArticle?.externalURL = externalLink
                }
            case "link":
                if feedType == .rss {
                    currentArticle?.url = text
                }
            case "author", "dc:creator":
                currentArticle?.author = text
            case "pubdate", "published", "updated", "dc:date":
                currentArticle?.publishedDate = parseDate(text) ?? Date()
            case "item", "entry":
                if var article = currentArticle {
                    // Use summary as content if content is empty
                    if article.content.isEmpty {
                        article.content = article.summary
                    }
                    // Use content as summary if summary is empty
                    if article.summary.isEmpty {
                        article.summary = article.content
                    }
                    articles.append(article)
                }
                currentArticle = nil
                isInsideItem = false
                isInsideEntry = false
            default:
                break
            }
        } else {
            // Parsing feed metadata
            switch element {
            case "title":
                if feedTitle.isEmpty {
                    feedTitle = text
                }
            case "description", "subtitle":
                if feedDescription.isEmpty {
                    feedDescription = text
                }
            case "link":
                if feedType == .rss && feedLink.isEmpty {
                    feedLink = text
                }
            default:
                break
            }
        }
        
        currentText = ""
    }
    
    // MARK: - Helpers
    
    private func parseDate(_ string: String) -> Date? {
        let formatters: [DateFormatter] = [
            Self.rfc822Formatter,
            Self.iso8601Formatter,
            Self.iso8601FractionalFormatter
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        // Try ISO8601DateFormatter as fallback
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) {
            return date
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: string)
    }
    
    // Date formatters (static for performance)
    private static let rfc822Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()
    
    private static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    private static let iso8601FractionalFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    /// Extract external link from HTML content (for Reddit posts)
    private func extractExternalLink(from html: String) -> String? {
        // Look for [link] anchor which Reddit uses for external links
        // Pattern: <a href="...">[link]</a>
        let pattern = #"<a\s+href="([^"]+)"[^>]*>\[link\]</a>"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let url = String(html[range])
            // Skip reddit internal links
            if !url.contains("reddit.com") && !url.contains("redd.it") {
                return url
            }
        }
        
        return nil
    }
}

// MARK: - Errors

enum FeedParserError: LocalizedError {
    case unknownError
    case invalidData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "An unknown error occurred while parsing the feed."
        case .invalidData:
            return "The feed data is invalid or corrupted."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
