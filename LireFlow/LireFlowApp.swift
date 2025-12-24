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
}
