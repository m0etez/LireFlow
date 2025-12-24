import Foundation

/// Service for extracting full article content from web pages
final class ArticleExtractor {

    /// EZProxy base URL (configure via ConfigService for institutional access)
    static let ezproxyBaseURL = ""  // Configure this in your config.json if needed
    
    /// Extract readable content from a web page URL
    static func extractContent(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw ArticleExtractorError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ArticleExtractorError.fetchFailed
        }
        
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ArticleExtractorError.invalidContent
        }
        
        return extractMainContent(from: html)
    }
    
    /// Extract content via EZProxy (for paywalled articles)
    static func extractContentViaProxy(from urlString: String) async throws -> String {
        // Build EZProxy URL with proper encoding
        guard let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              !ezproxyBaseURL.isEmpty,
              let proxyURL = URL(string: "\(ezproxyBaseURL)\(encodedURL)") else {
            throw ArticleExtractorError.invalidURL
        }
        
        // Create a URLSession that follows redirects and handles cookies
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        let session = URLSession(configuration: config)
        
        var request = URLRequest(url: proxyURL)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ArticleExtractorError.fetchFailed
        }
        
        // Check if we got redirected to login page
        if httpResponse.url?.absoluteString.contains("login") == true {
            throw ArticleExtractorError.proxyLoginRequired
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ArticleExtractorError.fetchFailed
        }
        
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ArticleExtractorError.invalidContent
        }
        
        return extractMainContent(from: html)
    }
    
    /// Extract main article content from HTML
    private static func extractMainContent(from html: String) -> String {
        // Try to find content in common article containers
        let contentPatterns = [
            // Main article tags
            #"<article[^>]*>(.*?)</article>"#,
            // Common content classes
            #"<div[^>]*class=\"[^\"]*(?:article-content|article-body|post-content|entry-content|content-body|story-body|article__body|post-body)[^\"]*\"[^>]*>(.*?)</div>"#,
            // Main content area
            #"<main[^>]*>(.*?)</main>"#,
            // Common IDs
            #"<div[^>]*id=\"(?:content|main-content|article|post)[^\"]*\"[^>]*>(.*?)</div>"#,
        ]
        
        for pattern in contentPatterns {
            if let content = extractWithPattern(pattern, from: html) {
                let cleaned = cleanHTML(content)
                if cleaned.count > 200 { // Only use if substantial content
                    return cleaned
                }
            }
        }
        
        // Fallback: try to get all paragraph content
        return extractParagraphs(from: html)
    }
    
    /// Extract content using regex pattern
    private static func extractWithPattern(_ pattern: String, from html: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            if let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)) {
                if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: html) {
                    return String(html[range])
                } else if let range = Range(match.range, in: html) {
                    return String(html[range])
                }
            }
        } catch {
            // Pattern failed, continue to next
        }
        return nil
    }
    
    /// Extract all paragraphs from HTML
    private static func extractParagraphs(from html: String) -> String {
        var paragraphs: [String] = []
        
        let pattern = #"<p[^>]*>(.*?)</p>"#
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let matches = regex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
            
            for match in matches {
                if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: html) {
                    let text = String(html[range])
                    let cleaned = stripTags(text).trimmingCharacters(in: .whitespacesAndNewlines)
                    // Only include paragraphs with substantial text
                    if cleaned.count > 50 {
                        paragraphs.append("<p>\(text)</p>")
                    }
                }
            }
        } catch {
            // Failed to extract paragraphs
        }
        
        return paragraphs.joined(separator: "\n")
    }
    
    /// Clean HTML content - remove scripts, styles, etc.
    private static func cleanHTML(_ html: String) -> String {
        var result = html
        
        // Remove scripts
        result = result.replacingOccurrences(of: #"<script[^>]*>.*?</script>"#, with: "", options: [.regularExpression, .caseInsensitive])
        
        // Remove styles
        result = result.replacingOccurrences(of: #"<style[^>]*>.*?</style>"#, with: "", options: [.regularExpression, .caseInsensitive])
        
        // Remove comments
        result = result.replacingOccurrences(of: #"<!--.*?-->"#, with: "", options: [.regularExpression])
        
        // Remove navigation, header, footer, aside
        let tagsToRemove = ["nav", "header", "footer", "aside", "form", "noscript"]
        for tag in tagsToRemove {
            result = result.replacingOccurrences(of: #"<\#(tag)[^>]*>.*?</\#(tag)>"#, with: "", options: [.regularExpression, .caseInsensitive])
        }
        
        // Remove common ad/social divs
        result = result.replacingOccurrences(of: #"<div[^>]*class=\"[^\"]*(?:ad-|advertisement|social-share|share-buttons|related-posts|sidebar)[^\"]*\"[^>]*>.*?</div>"#, with: "", options: [.regularExpression, .caseInsensitive])
        
        // Clean up whitespace
        result = result.replacingOccurrences(of: #"\n\s*\n"#, with: "\n", options: .regularExpression)
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Strip all HTML tags
    private static func stripTags(_ html: String) -> String {
        html.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
    }
}

// MARK: - Errors

enum ArticleExtractorError: LocalizedError {
    case invalidURL
    case fetchFailed
    case invalidContent
    case proxyLoginRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid article URL"
        case .fetchFailed:
            return "Failed to fetch the article"
        case .invalidContent:
            return "Could not read the article content"
        case .proxyLoginRequired:
            return "Please log in to the university proxy first (click Paris-Saclay Library button)"
        }
    }
}
