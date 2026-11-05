import Foundation
import AppKit
import SwiftData
import UniformTypeIdentifiers

@MainActor
final class ImportService: ObservableObject {

    // MARK: - Error Types

    enum ImportError: LocalizedError {
        case fileReadFailed(Error)
        case invalidFormat
        case decodingFailed(Error)
        case unsupportedVersion(Int)
        case xmlParsingFailed(Error)
        case userCancelled

        var errorDescription: String? {
            switch self {
            case .fileReadFailed(let error):
                return "Failed to read file: \(error.localizedDescription)"
            case .invalidFormat:
                return "Invalid file format. Please select a valid LireFlow JSON or OPML file."
            case .decodingFailed(let error):
                return "Failed to decode file: \(error.localizedDescription)"
            case .unsupportedVersion(let version):
                return "Unsupported file version (\(version)). Please update LireFlow to the latest version."
            case .xmlParsingFailed(let error):
                return "Failed to parse OPML file: \(error.localizedDescription)"
            case .userCancelled:
                return nil  // Silent error
            }
        }
    }

    // MARK: - Import Result

    struct ImportResult {
        let foldersImported: Int
        let feedsImported: Int
        let readingListsImported: Int
        let duplicatesSkipped: Int
        /// Feeds and reading lists not imported because the free tier is full
        let limitSkipped: Int

        var totalImported: Int {
            foldersImported + feedsImported + readingListsImported
        }
    }

    // MARK: - JSON Import

    /// Import library from JSON (merge with existing data)
    func importFromJSON(in context: ModelContext) async throws -> ImportResult {

        // 1. Present open panel
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Import Library from JSON"
        openPanel.message = "Select a LireFlow JSON export file"

        guard openPanel.runModal() == .OK,
              let url = openPanel.url else {
            throw ImportError.userCancelled
        }

        // 2. Read and decode JSON
        let jsonData: Data
        do {
            jsonData = try Data(contentsOf: url)
        } catch {
            throw ImportError.fileReadFailed(error)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData: LireFlowExport
        do {
            exportData = try decoder.decode(LireFlowExport.self, from: jsonData)
        } catch {
            throw ImportError.decodingFailed(error)
        }

        // 3. Version check
        guard exportData.version == 1 else {
            throw ImportError.unsupportedVersion(exportData.version)
        }

        // 4. Merge data with duplicate detection
        return try await mergeData(exportData, in: context)
    }

    // MARK: - OPML Import

    /// Import feeds from OPML file (merge with existing)
    func importFromOPML(in context: ModelContext) async throws -> ImportResult {

        // 1. Present open panel
        let openPanel = NSOpenPanel()
        if let opmlType = UTType(filenameExtension: "opml") {
            openPanel.allowedContentTypes = [opmlType, .xml]
        }
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Import Feeds from OPML"
        openPanel.message = "Select an OPML file"

        guard openPanel.runModal() == .OK,
              let url = openPanel.url else {
            throw ImportError.userCancelled
        }

        // 2. Parse OPML XML
        let xmlData: Data
        do {
            xmlData = try Data(contentsOf: url)
        } catch {
            throw ImportError.fileReadFailed(error)
        }

        let opmlData: OPMLData
        do {
            opmlData = try Self.parseOPML(xmlData)
        } catch {
            throw ImportError.xmlParsingFailed(error)
        }

        // 3. Merge data
        return try await mergeOPMLData(opmlData, in: context)
    }

    // MARK: - Private Merge Logic

    private func mergeData(
        _ exportData: LireFlowExport,
        in context: ModelContext
    ) async throws -> ImportResult {

        var foldersImported = 0
        var feedsImported = 0
        var readingListsImported = 0
        var duplicatesSkipped = 0
        var limitSkipped = 0
        let store = StoreService.shared

        // 1. Fetch existing data for duplicate detection
        var knownFeedURLs = Set(try context.fetch(FetchDescriptor<Feed>()).map { $0.url })
        let existingFolders = try context.fetch(FetchDescriptor<Folder>())
        let existingReadingLists = try context.fetch(FetchDescriptor<ReadingList>())
        let existingReadingListIDs = Set(existingReadingLists.map { $0.id })

        // 2. Import folders first (maintain ID mapping)
        var folderIDMapping: [UUID: Folder] = Dictionary(
            existingFolders.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }
        )

        for exportFolder in exportData.folders {
            if folderIDMapping[exportFolder.id] != nil {
                duplicatesSkipped += 1
                continue
            }

            let folder = Folder(
                id: exportFolder.id,
                name: exportFolder.name,
                order: exportFolder.order,
                icon: exportFolder.icon
            )
            context.insert(folder)
            folderIDMapping[exportFolder.id] = folder
            foldersImported += 1
        }

        // 3. Import feeds (skip duplicates by URL, respect the free tier)
        for exportFeed in exportData.feeds {
            guard knownFeedURLs.insert(exportFeed.url).inserted else {
                duplicatesSkipped += 1
                continue
            }
            guard store.canAddFeed(currentCount: knownFeedURLs.count - 1) else {
                limitSkipped += 1
                continue
            }

            let feed = Feed(
                id: exportFeed.id,
                title: exportFeed.title,
                feedDescription: exportFeed.feedDescription,
                url: exportFeed.url,
                websiteURL: exportFeed.websiteURL,
                iconURL: exportFeed.iconURL,
                folder: exportFeed.folderID.flatMap { folderIDMapping[$0] }
            )
            context.insert(feed)
            feedsImported += 1
        }

        // 4. Import reading lists (skip duplicates by ID, respect the free tier)
        for exportList in exportData.readingLists {
            if existingReadingListIDs.contains(exportList.id) {
                duplicatesSkipped += 1
                continue
            }
            guard store.canAddReadingList(currentCount: existingReadingLists.count + readingListsImported) else {
                limitSkipped += 1
                continue
            }

            let readingList = ReadingList(
                id: exportList.id,
                name: exportList.name,
                icon: exportList.icon,
                createdAt: exportList.createdAt
            )
            context.insert(readingList)
            readingListsImported += 1
        }

        // 5. Save changes
        try context.save()

        return ImportResult(
            foldersImported: foldersImported,
            feedsImported: feedsImported,
            readingListsImported: readingListsImported,
            duplicatesSkipped: duplicatesSkipped,
            limitSkipped: limitSkipped
        )
    }

    /// Parse OPML into top-level folders and loose feeds. An outline is a feed when it has an
    /// `xmlUrl` (many exporters omit `type="rss"`); deeper nesting is flattened into its top folder.
    static func parseOPML(_ xmlData: Data) throws -> OPMLData {
        let xmlDoc = try XMLDocument(data: xmlData, options: [.nodeLoadExternalEntitiesNever])

        guard let bodyElement = try xmlDoc.nodes(forXPath: "//body").first else {
            throw ImportError.invalidFormat
        }

        var folders: [OPMLFolder] = []
        var orphanedFeeds: [OPMLFeed] = []

        let outlines = try bodyElement.nodes(forXPath: "outline") as? [XMLElement] ?? []

        for outline in outlines {
            if let feed = parseFeedOutline(outline, folderName: nil) {
                orphanedFeeds.append(feed)
                continue
            }

            let folderName = outline.attribute(forName: "text")?.stringValue
                ?? outline.attribute(forName: "title")?.stringValue
                ?? "Unnamed Folder"
            let nestedFeeds = (try outline.nodes(forXPath: ".//outline") as? [XMLElement] ?? [])
                .compactMap { parseFeedOutline($0, folderName: folderName) }

            if !nestedFeeds.isEmpty {
                folders.append(OPMLFolder(name: folderName, feeds: nestedFeeds))
            }
        }

        return OPMLData(folders: folders, feeds: orphanedFeeds)
    }

    private static func parseFeedOutline(_ outline: XMLElement, folderName: String?) -> OPMLFeed? {
        guard let feedURL = outline.attribute(forName: "xmlUrl")?.stringValue,
              !feedURL.isEmpty else {
            return nil
        }

        // text="" is common in exported OPML: treat empty like missing
        let title = [outline.attribute(forName: "text")?.stringValue, outline.attribute(forName: "title")?.stringValue]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
            ?? FeedService.fallbackTitle(for: feedURL)
        let websiteURL = outline.attribute(forName: "htmlUrl")?.stringValue
        let description = outline.attribute(forName: "description")?.stringValue

        return OPMLFeed(
            title: title,
            feedURL: feedURL,
            websiteURL: websiteURL,
            description: description,
            folderName: folderName
        )
    }

    private func mergeOPMLData(
        _ opmlData: OPMLData,
        in context: ModelContext
    ) async throws -> ImportResult {

        var foldersImported = 0
        var feedsImported = 0
        var duplicatesSkipped = 0
        var limitSkipped = 0
        let store = StoreService.shared

        // 1. Fetch existing data
        var knownFeedURLs = Set(try context.fetch(FetchDescriptor<Feed>()).map { $0.url })

        let existingFolders = try context.fetch(FetchDescriptor<Folder>())
        // Folder names aren't unique: keep the first match instead of crashing on duplicates
        var foldersByName: [String: Folder] = Dictionary(
            existingFolders.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first }
        )

        /// Insert one feed unless it's a duplicate or over the free limit
        func importFeed(_ opmlFeed: OPMLFeed, into folder: Folder?) {
            guard knownFeedURLs.insert(opmlFeed.feedURL).inserted else {
                duplicatesSkipped += 1
                return
            }
            guard store.canAddFeed(currentCount: knownFeedURLs.count - 1) else {
                limitSkipped += 1
                return
            }
            context.insert(Feed(
                id: UUID(),
                title: opmlFeed.title,
                feedDescription: opmlFeed.description ?? "",
                url: opmlFeed.feedURL,
                websiteURL: opmlFeed.websiteURL,
                iconURL: nil,
                folder: folder
            ))
            feedsImported += 1
        }

        // 2. Import folders and their feeds
        for opmlFolder in opmlData.folders {
            let folder: Folder
            if let existingFolder = foldersByName[opmlFolder.name] {
                folder = existingFolder
            } else {
                folder = Folder(
                    id: UUID(),
                    name: opmlFolder.name,
                    order: existingFolders.count + foldersImported,
                    icon: "folder"
                )
                context.insert(folder)
                foldersByName[opmlFolder.name] = folder
                foldersImported += 1
            }

            opmlFolder.feeds.forEach { importFeed($0, into: folder) }
        }

        // 3. Import orphaned feeds (no folder)
        opmlData.feeds.forEach { importFeed($0, into: nil) }

        // 4. Save changes
        try context.save()

        return ImportResult(
            foldersImported: foldersImported,
            feedsImported: feedsImported,
            readingListsImported: 0,  // OPML doesn't support reading lists
            duplicatesSkipped: duplicatesSkipped,
            limitSkipped: limitSkipped
        )
    }
}
