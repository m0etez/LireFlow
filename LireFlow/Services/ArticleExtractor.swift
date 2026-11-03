import Foundation
import WebKit

/// Fetches an article page and pulls the story out of it with Mozilla's Readability.js (the
/// engine behind Firefox Reader View, bundled in Resources), run in an offscreen web view so
/// the page gets a real HTML5 parser.
@MainActor
enum ArticleExtractor {

    /// Maximum HTML size to process (10MB)
    private static let maxHTMLSize = 10 * 1024 * 1024

    /// Readability.js; the self-check points this at the repo copy
    static var readabilityURL = Bundle.main.url(forResource: "Readability", withExtension: "js")

    /// Extract readable content from a web page URL
    static func extractContent(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw ArticleExtractorError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 15_2_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ArticleExtractorError.fetchFailed
        }

        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ArticleExtractorError.invalidContent
        }

        guard html.utf8.count <= maxHTMLSize else {
            throw ArticleExtractorError.contentTooLarge
        }

        // After redirects, relative URLs resolve against the final page
        return try await extractMainContent(from: html, baseURL: httpResponse.url ?? url)
    }

    /// The story's HTML, with absolute links and image URLs, or "" when Readability finds none
    static func extractMainContent(from html: String, baseURL: URL) async throws -> String {
        guard let readabilityURL, let readability = try? String(contentsOf: readabilityURL, encoding: .utf8) else {
            throw ArticleExtractorError.readerUnavailable
        }

        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false  // page scripts never run
        let webView = WKWebView(frame: .zero, configuration: configuration)
        let loader = BlankPageLoader()
        try await loader.load(into: webView)

        // DOMParser documents are inert: no scripts run and no images or styles load
        let script = readability + """

        const doc = new DOMParser().parseFromString(html, "text/html");
        if (!doc.querySelector("base[href]")) {
            const base = doc.createElement("base");
            base.href = url;  // so Readability resolves relative links and images against the article
            doc.head.prepend(base);
        }
        const article = new Readability(doc).parse();
        return article ? article.content : "";
        """
        let result = try await webView.callAsyncJavaScript(
            script,
            arguments: ["html": html, "url": baseURL.absoluteString],
            in: nil,
            contentWorld: .defaultClient
        )
        return result as? String ?? ""
    }
}

/// Loads an empty page and waits for it, so scripts have a document to run in
@MainActor
private final class BlankPageLoader: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Error>?

    func load(into webView: WKWebView) async throws {
        webView.navigationDelegate = self
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            webView.loadHTMLString("<!DOCTYPE html><html><head></head><body></body></html>", baseURL: nil)
        }
        webView.navigationDelegate = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation?.resume()
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

// MARK: - Errors

enum ArticleExtractorError: LocalizedError {
    case invalidURL
    case fetchFailed
    case invalidContent
    case contentTooLarge
    case readerUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "Invalid article URL")
        case .fetchFailed:
            return String(localized: "Couldn’t load the article page.")
        case .invalidContent:
            return String(localized: "Couldn’t read the article page.")
        case .contentTooLarge:
            return String(localized: "The article page is too large to process.")
        case .readerUnavailable:
            return String(localized: "The article reader is missing from the app. Reinstall LireFlow.")
        }
    }
}
