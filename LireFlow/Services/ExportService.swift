import Foundation
import AppKit
import UniformTypeIdentifiers

@MainActor
final class ExportService: ObservableObject {

    // MARK: - Error Types

    enum ExportError: LocalizedError {
        case noDataToExport
        case fileWriteFailed(Error)
        case encodingFailed(Error)
        case userCancelled

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
}
