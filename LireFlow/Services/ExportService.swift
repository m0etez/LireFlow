import Foundation
import AppKit
import UniformTypeIdentifiers
import WebKit

@MainActor
final class ExportService: ObservableObject {

    // MARK: - Error Types

    enum ExportError: LocalizedError {
        case noDataToExport
        case fileWriteFailed(Error)
        case encodingFailed(Error)
        case userCancelled
        case pdfGenerationFailed(Error)

        var errorDescription: String? {
            switch self {
            case .noDataToExport:
                return "No data to export"
            case .fileWriteFailed(let error):
                return "Failed to write file: \(error.localizedDescription)"
            case .encodingFailed(let error):
                return "Failed to encode data: \(error.localizedDescription)"
            case .userCancelled:
                return nil  // Silent error
            case .pdfGenerationFailed(let error):
                return "Failed to generate PDF: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - JSON Export

    /// Export library to JSON format
    func exportToJSON(
        folders: [Folder],
        feeds: [Feed],
        readingLists: [ReadingList]
    ) async throws -> URL {

        // 1. Convert SwiftData models to Codable DTOs
        let exportData = LireFlowExport(
            exportedAt: Date(),
            folders: folders.map { ExportableFolder(from: $0) },
            feeds: feeds.map { ExportableFeed(from: $0) },
            readingLists: readingLists.map { ExportableReadingList(from: $0) }
        )

        // 2. Encode to JSON with pretty printing
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData: Data
        do {
            jsonData = try encoder.encode(exportData)
        } catch {
            throw ExportError.encodingFailed(error)
        }

        // 3. Present save panel
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "LireFlow-Export-\(dateString()).json"
        savePanel.allowedContentTypes = [.json]
        savePanel.canCreateDirectories = true
        savePanel.title = "Export Library to JSON"
        savePanel.message = "Choose where to save your LireFlow library backup"

        guard savePanel.runModal() == .OK,
              let url = savePanel.url else {
            throw ExportError.userCancelled
        }

        // 4. Write to file
        do {
            try jsonData.write(to: url, options: .atomic)
        } catch {
            throw ExportError.fileWriteFailed(error)
        }

        return url
    }

    // MARK: - OPML Export

    /// Export feeds to OPML format (standard RSS format)
    func exportToOPML(
        folders: [Folder],
        feeds: [Feed]
    ) async throws -> URL {

        // 1. Build OPML XML structure
        let opmlContent = buildOPMLDocument(folders: folders, feeds: feeds)

        // 2. Present save panel
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "LireFlow-Export-\(dateString()).opml"
        if let opmlType = UTType(filenameExtension: "opml") {
            savePanel.allowedContentTypes = [opmlType]
        }
        savePanel.canCreateDirectories = true
        savePanel.title = "Export Feeds to OPML"
        savePanel.message = "Choose where to save your feed list"

        guard savePanel.runModal() == .OK,
              let url = savePanel.url else {
            throw ExportError.userCancelled
        }

        // 3. Write to file
        do {
            try opmlContent.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.fileWriteFailed(error)
        }

        return url
    }

    // MARK: - Article PDF Export

    /// Export single article to PDF format
    func exportArticleToPDF(article: Article) async throws -> URL {
        // 1. Generate print-ready HTML (clean, no logo)
        let displayContent = article.content.isEmpty ? article.summary : article.content
        let htmlContent = buildArticlePrintHTML(article: article, content: displayContent)

        // 2. Present save panel
        let savePanel = NSSavePanel()
        let sanitizedTitle = sanitizeFilename(article.displayTitle)
        savePanel.nameFieldStringValue = "\(sanitizedTitle).pdf"
        savePanel.allowedContentTypes = [.pdf]
        savePanel.canCreateDirectories = true
        savePanel.title = "Export Article to PDF"
        savePanel.message = "Choose where to save the PDF"

        guard savePanel.runModal() == .OK,
              let url = savePanel.url else {
            throw ExportError.userCancelled
        }

        // 3. Generate PDF using WebKit
        do {
            try await generatePDF(from: htmlContent, to: url)
        } catch {
            throw ExportError.pdfGenerationFailed(error)
        }

        return url
    }

    // MARK: - Article Markdown Export

    /// Export single article to Markdown format
    func exportArticleToMarkdown(article: Article) async throws -> URL {
        // 1. Generate markdown content
        let markdown = buildArticleMarkdown(article: article)

        // 2. Present save panel
        let savePanel = NSSavePanel()
        let sanitizedTitle = sanitizeFilename(article.displayTitle)
        savePanel.nameFieldStringValue = "\(sanitizedTitle).md"
        if let markdownType = UTType(filenameExtension: "md") {
            savePanel.allowedContentTypes = [markdownType, .plainText]
        } else {
            savePanel.allowedContentTypes = [.plainText]
        }
        savePanel.canCreateDirectories = true
        savePanel.title = "Export Article to Markdown"
        savePanel.message = "Choose where to save the Markdown file"

        guard savePanel.runModal() == .OK,
              let url = savePanel.url else {
            throw ExportError.userCancelled
        }

        // 3. Write to file
        do {
            try markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.fileWriteFailed(error)
        }

        return url
    }

    // MARK: - Private Helpers

    private func buildOPMLDocument(folders: [Folder], feeds: [Feed]) -> String {
        var opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
          <head>
            <title>LireFlow Subscriptions</title>
            <dateCreated>\(rfc822Date(Date()))</dateCreated>
            <docs>https://opml.org/spec2.opml</docs>
          </head>
          <body>

        """

        // Group feeds by folder
        let feedsByFolder = Dictionary(grouping: feeds) { $0.folder?.id }

        // Add feeds without folders first
        if let orphanedFeeds = feedsByFolder[nil], !orphanedFeeds.isEmpty {
            for feed in orphanedFeeds.sorted(by: { $0.title < $1.title }) {
                opml += buildFeedOutline(feed, indent: 2)
            }
        }

        // Add folders with their feeds
        for folder in folders.sorted(by: { $0.order < $1.order }) {
            opml += "    <outline text=\"\(xmlEscape(folder.name))\">\n"

            if let folderFeeds = feedsByFolder[folder.id] {
                for feed in folderFeeds.sorted(by: { $0.title < $1.title }) {
                    opml += buildFeedOutline(feed, indent: 3)
                }
            }

            opml += "    </outline>\n"
        }

        opml += """
          </body>
        </opml>
        """

        return opml
    }

    private func buildFeedOutline(_ feed: Feed, indent: Int) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var outline = "\(indentStr)<outline"

        outline += " text=\"\(xmlEscape(feed.title))\""
        outline += " type=\"rss\""
        outline += " xmlUrl=\"\(xmlEscape(feed.url))\""

        if let websiteURL = feed.websiteURL {
            outline += " htmlUrl=\"\(xmlEscape(websiteURL))\""
        }

        if !feed.feedDescription.isEmpty {
            outline += " description=\"\(xmlEscape(feed.feedDescription))\""
        }

        outline += "/>\n"

        return outline
    }

    private func xmlEscape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func rfc822Date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    // MARK: - PDF Generation Helpers

    private func buildArticlePrintHTML(article: Article, content: String) -> String {
        // Match existing print pattern from ArticleDetailView (clean, no logo)
        return """
        <html>
        <head>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif;
                    font-size: 12pt;
                    line-height: 1.6;
                    margin: 40px;
                    color: #1d1d1f;
                }
                h1 {
                    font-size: 24pt;
                    font-weight: 600;
                    margin-bottom: 20px;
                }
                .metadata {
                    font-size: 10pt;
                    color: #666;
                    margin-bottom: 20px;
                    padding-bottom: 10px;
                    border-bottom: 1px solid #ddd;
                }
                img {
                    max-width: 100%;
                    height: auto;
                }
            </style>
        </head>
        <body>
            <h1>\(article.displayTitle)</h1>
            <div class="metadata">
                \(article.author.map { "By \($0)<br>" } ?? "")
                \(article.feed.map { "\($0.title)<br>" } ?? "")
                \(article.publishedDate.formatted(date: .long, time: .omitted))<br>
                \(article.url)
            </div>
            \(content)
        </body>
        </html>
        """
    }

    private func generatePDF(from html: String, to url: URL) async throws {
        // Use WKWebView to render HTML to PDF
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 612, height: 792))
        webView.loadHTMLString(html, baseURL: nil)

        // Wait for load to complete
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var observer: NSKeyValueObservation?
            observer = webView.observe(\.isLoading, options: [.new]) { webView, change in
                if webView.isLoading == false {
                    observer?.invalidate()

                    // Generate PDF
                    let config = WKPDFConfiguration()
                    config.rect = CGRect(x: 0, y: 0, width: 612, height: 792)

                    webView.createPDF(configuration: config) { result in
                        switch result {
                        case .success(let data):
                            do {
                                try data.write(to: url, options: .atomic)
                                continuation.resume()
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }

    private func sanitizeFilename(_ filename: String) -> String {
        // Remove invalid filename characters
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        let sanitized = filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespaces)

        // Truncate to 100 characters
        if sanitized.count > 100 {
            return String(sanitized.prefix(100))
        }
        return sanitized
    }

    // MARK: - Markdown Generation Helper

    private func buildArticleMarkdown(article: Article) -> String {
        var markdown = ""

        // Title
        markdown += "# \(article.displayTitle)\n\n"

        // Metadata
        if let author = article.author, !author.isEmpty {
            markdown += "**Author:** \(author)\n\n"
        }
        if let feed = article.feed {
            markdown += "**Source:** \(feed.title)\n\n"
        }
        markdown += "**Date:** \(article.publishedDate.formatted(date: .long, time: .omitted))\n\n"
        markdown += "**URL:** [\(article.url)](\(article.url))\n\n"
        markdown += "---\n\n"

        // Content (convert HTML to plain text)
        let content = article.content.isEmpty ? article.summary : article.content
        let strippedContent = content.strippingHTML.decodingHTMLEntities
        markdown += strippedContent

        return markdown
    }
}
