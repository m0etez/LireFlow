import SwiftUI
import SwiftData

/// Shared app configuration and model container
/// Used by both macOS and iOS targets
struct LireFlowAppCore {
    /// Shared SwiftData model container
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Feed.self,
            Article.self,
            Folder.self,
            ReadingList.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

// MARK: - Notification Names
extension Notification.Name {
    static let addNewFeed = Notification.Name("addNewFeed")
    static let addNewFolder = Notification.Name("addNewFolder")
    static let refreshAllFeeds = Notification.Name("refreshAllFeeds")
    static let exportToJSON = Notification.Name("exportToJSON")
    static let exportToOPML = Notification.Name("exportToOPML")
    static let importFromJSON = Notification.Name("importFromJSON")
    static let importFromOPML = Notification.Name("importFromOPML")
    static let showSettings = Notification.Name("showSettings")
    static let nextArticle = Notification.Name("nextArticle")
    static let previousArticle = Notification.Name("previousArticle")
    static let toggleRead = Notification.Name("toggleRead")
    static let markAllAsRead = Notification.Name("markAllAsRead")
    static let toggleStar = Notification.Name("toggleStar")
    static let openInBrowser = Notification.Name("openInBrowser")
    static let openArticle = Notification.Name("openArticle")
    static let articleSelectionChanged = Notification.Name("articleSelectionChanged")
}
