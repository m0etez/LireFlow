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
            openPanel.allowedContentTypes = [opmlType]
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
            opmlData = try parseOPML(xmlData)
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

        // 1. Fetch existing data for duplicate detection
        let existingFeeds = try context.fetch(FetchDescriptor<Feed>())
        let existingFeedURLs = Set(existingFeeds.map { $0.url })
        let existingFolderIDs = Set(try context.fetch(FetchDescriptor<Folder>()).map { $0.id })
        let existingReadingListIDs = Set(try context.fetch(FetchDescriptor<ReadingList>()).map { $0.id })

        // 2. Import folders first (maintain ID mapping)
        var folderIDMapping: [UUID: Folder] = [:]

        for exportFolder in exportData.folders {
            if existingFolderIDs.contains(exportFolder.id) {
                duplicatesSkipped += 1
                // Load existing folder for reference
                let descriptor = FetchDescriptor<Folder>(
                    predicate: #Predicate { $0.id == exportFolder.id }
                )
                if let existing = try context.fetch(descriptor).first {
                    folderIDMapping[exportFolder.id] = existing
                }
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

        // 3. Import feeds (skip duplicates by URL)
        for exportFeed in exportData.feeds {
            if existingFeedURLs.contains(exportFeed.url) {
                duplicatesSkipped += 1
                continue
            }

            let folder = exportFeed.folderID.flatMap { folderIDMapping[$0] }

            let feed = Feed(
                id: exportFeed.id,
                title: exportFeed.title,
                feedDescription: exportFeed.feedDescription,
                url: exportFeed.url,
                websiteURL: exportFeed.websiteURL,
                iconURL: exportFeed.iconURL,
                folder: folder
            )
            context.insert(feed)
            feedsImported += 1
        }

        // 4. Import reading lists (skip duplicates by ID)
        for exportList in exportData.readingLists {
            if existingReadingListIDs.contains(exportList.id) {
                duplicatesSkipped += 1
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
            duplicatesSkipped: duplicatesSkipped
        )
    }

    private func parseOPML(_ xmlData: Data) throws -> OPMLData {
        let xmlDoc = try XMLDocument(data: xmlData, options: [])

        guard let bodyElement = try xmlDoc.nodes(forXPath: "//body").first else {
            throw ImportError.invalidFormat
        }

        var folders: [OPMLFolder] = []
        var orphanedFeeds: [OPMLFeed] = []

        // Parse all outline elements under body
        let outlines = try bodyElement.nodes(forXPath: "outline") as? [XMLElement] ?? []

        for outline in outlines {
            // Check if this is a feed or a folder
            let type = outline.attribute(forName: "type")?.stringValue

            if type == "rss" {
                // This is a feed without a folder
                if let feed = parseFeedOutline(outline, folderName: nil) {
                    orphanedFeeds.append(feed)
                }
            } else {
                // This is a folder (has no type attribute or type != "rss")
                let folderName = outline.attribute(forName: "text")?.stringValue ?? "Unnamed Folder"
                var folderFeeds: [OPMLFeed] = []

                // Parse nested feeds
                let nestedOutlines = try outline.nodes(forXPath: "outline") as? [XMLElement] ?? []
                for nestedOutline in nestedOutlines {
                    if let feed = parseFeedOutline(nestedOutline, folderName: folderName) {
                        folderFeeds.append(feed)
                    }
                }

                if !folderFeeds.isEmpty {
                    folders.append(OPMLFolder(name: folderName, feeds: folderFeeds))
                }
            }
        }

        return OPMLData(folders: folders, feeds: orphanedFeeds)
    }

    private func parseFeedOutline(_ outline: XMLElement, folderName: String?) -> OPMLFeed? {
        guard let feedURL = outline.attribute(forName: "xmlUrl")?.stringValue else {
            return nil
        }

        let title = outline.attribute(forName: "text")?.stringValue ?? feedURL
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

        // 1. Fetch existing data
        let existingFeeds = try context.fetch(FetchDescriptor<Feed>())
        let existingFeedURLs = Set(existingFeeds.map { $0.url })

        let existingFolders = try context.fetch(FetchDescriptor<Folder>())
        var foldersByName: [String: Folder] = Dictionary(
            uniqueKeysWithValues: existingFolders.map { ($0.name, $0) }
        )

        // 2. Import folders and their feeds
        for opmlFolder in opmlData.folders {
            // Get or create folder
            let folder: Folder
            if let existingFolder = foldersByName[opmlFolder.name] {
                folder = existingFolder
            } else {
                let newFolder = Folder(
                    id: UUID(),
                    name: opmlFolder.name,
                    order: existingFolders.count + foldersImported,
                    icon: "folder"
                )
                context.insert(newFolder)
                foldersByName[opmlFolder.name] = newFolder
                folder = newFolder
                foldersImported += 1
            }

            // Import feeds in this folder
            for opmlFeed in opmlFolder.feeds {
                if existingFeedURLs.contains(opmlFeed.feedURL) {
                    duplicatesSkipped += 1
                    continue
                }

                let feed = Feed(
                    id: UUID(),
                    title: opmlFeed.title,
                    feedDescription: opmlFeed.description ?? "",
                    url: opmlFeed.feedURL,
                    websiteURL: opmlFeed.websiteURL,
                    iconURL: nil,
                    folder: folder
                )
                context.insert(feed)
                feedsImported += 1
            }
        }

        // 3. Import orphaned feeds (no folder)
        for opmlFeed in opmlData.feeds {
            if existingFeedURLs.contains(opmlFeed.feedURL) {
                duplicatesSkipped += 1
                continue
            }

            let feed = Feed(
                id: UUID(),
                title: opmlFeed.title,
                feedDescription: opmlFeed.description ?? "",
                url: opmlFeed.feedURL,
                websiteURL: opmlFeed.websiteURL,
                iconURL: nil,
                folder: nil
            )
            context.insert(feed)
            feedsImported += 1
        }

        // 4. Save changes
        try context.save()

        return ImportResult(
            foldersImported: foldersImported,
            feedsImported: feedsImported,
            readingListsImported: 0,  // OPML doesn't support reading lists
            duplicatesSkipped: duplicatesSkipped
        )
    }
}
