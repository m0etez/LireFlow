import Foundation

// MARK: - Export Container

/// Root export container for LireFlow library backup
struct LireFlowExport: Codable {
    let version: Int
    let exportedAt: Date
    let folders: [ExportableFolder]
    let feeds: [ExportableFeed]
    let readingLists: [ExportableReadingList]

    init(
        version: Int = 1,
        exportedAt: Date = Date(),
        folders: [ExportableFolder],
        feeds: [ExportableFeed],
        readingLists: [ExportableReadingList]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.folders = folders
        self.feeds = feeds
        self.readingLists = readingLists
    }
}

// MARK: - Exportable Models

/// Codable representation of Folder model
struct ExportableFolder: Codable, Identifiable {
    let id: UUID
    let name: String
    let order: Int
    let icon: String

    init(id: UUID, name: String, order: Int, icon: String) {
        self.id = id
        self.name = name
        self.order = order
        self.icon = icon
    }

    /// Create from SwiftData Folder model
    init(from folder: Folder) {
        self.id = folder.id
        self.name = folder.name
        self.order = folder.order
        self.icon = folder.icon
    }
}

/// Codable representation of Feed model
struct ExportableFeed: Codable, Identifiable {
    let id: UUID
    let title: String
    let feedDescription: String
    let url: String
    let websiteURL: String?
    let iconURL: String?
    let folderID: UUID?

    init(
        id: UUID,
        title: String,
        feedDescription: String,
        url: String,
        websiteURL: String? = nil,
        iconURL: String? = nil,
        folderID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.feedDescription = feedDescription
        self.url = url
        self.websiteURL = websiteURL
        self.iconURL = iconURL
        self.folderID = folderID
    }

    /// Create from SwiftData Feed model
    init(from feed: Feed) {
        self.id = feed.id
        self.title = feed.title
        self.feedDescription = feed.feedDescription
        self.url = feed.url
        self.websiteURL = feed.websiteURL
        self.iconURL = feed.iconURL
        self.folderID = feed.folder?.id
    }
}

/// Codable representation of ReadingList model
struct ExportableReadingList: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let createdAt: Date

    init(id: UUID, name: String, icon: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
    }

    /// Create from SwiftData ReadingList model
    init(from readingList: ReadingList) {
        self.id = readingList.id
        self.name = readingList.name
        self.icon = readingList.icon
        self.createdAt = readingList.createdAt
    }
}

// MARK: - OPML Data Structures

/// Intermediate structure for OPML parsing
struct OPMLData {
    let folders: [OPMLFolder]
    let feeds: [OPMLFeed]
}

/// OPML folder representation
struct OPMLFolder {
    let name: String
    let feeds: [OPMLFeed]
}

/// OPML feed representation
struct OPMLFeed {
    let title: String
    let feedURL: String
    let websiteURL: String?
    let description: String?
    let folderName: String?
}
