import SwiftUI
import SwiftData

@main
struct LireFlowApp: App {
    var sharedModelContainer: ModelContainer = {
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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Feed...") {
                    NotificationCenter.default.post(name: .addNewFeed, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Folder...") {
                    NotificationCenter.default.post(name: .addNewFolder, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandGroup(after: .importExport) {
                Menu("Export Library") {
                    Button("Export to JSON...") {
                        NotificationCenter.default.post(name: .exportToJSON, object: nil)
                    }
                    .keyboardShortcut("e", modifiers: [.command, .shift])

                    Button("Export to OPML...") {
                        NotificationCenter.default.post(name: .exportToOPML, object: nil)
                    }
                }

                Menu("Import Library") {
                    Button("Import from JSON...") {
                        NotificationCenter.default.post(name: .importFromJSON, object: nil)
                    }
                    .keyboardShortcut("i", modifiers: [.command, .shift])

                    Button("Import from OPML...") {
                        NotificationCenter.default.post(name: .importFromOPML, object: nil)
                    }
                }
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NotificationCenter.default.post(name: .showSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .toolbar) {
                Button("Refresh All Feeds") {
                    NotificationCenter.default.post(name: .refreshAllFeeds, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
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
}
