import SwiftUI
import SwiftData

@main
struct LireFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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

            CommandMenu("Article") {
                Button("Next Article") {
                    NotificationCenter.default.post(name: .nextArticle, object: nil)
                }
                .keyboardShortcut("j", modifiers: [])

                Button("Previous Article") {
                    NotificationCenter.default.post(name: .previousArticle, object: nil)
                }
                .keyboardShortcut("k", modifiers: [])

                Divider()

                Button("Mark as Read/Unread") {
                    NotificationCenter.default.post(name: .toggleRead, object: nil)
                }
                .keyboardShortcut("m", modifiers: [])

                Button("Mark All as Read") {
                    NotificationCenter.default.post(name: .markAllAsRead, object: nil)
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])

                Button("Toggle Star") {
                    NotificationCenter.default.post(name: .toggleStar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [])

                Divider()

                Button("Open in Browser") {
                    NotificationCenter.default.post(name: .openInBrowser, object: nil)
                }
                .keyboardShortcut("v", modifiers: [])
            }
        }
        
        // Menu Bar Extra
        MenuBarExtra {
            MenuBarView()
                .modelContainer(sharedModelContainer)
        } label: {
            Label("LireFlow", systemImage: "dot.radiowaves.up.forward")
        }
        .menuBarExtraStyle(.window)
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
    static let nextArticle = Notification.Name("nextArticle")
    static let previousArticle = Notification.Name("previousArticle")
    static let toggleRead = Notification.Name("toggleRead")
    static let markAllAsRead = Notification.Name("markAllAsRead")
    static let toggleStar = Notification.Name("toggleStar")
    static let openInBrowser = Notification.Name("openInBrowser")
    static let openArticle = Notification.Name("openArticle")
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let dockMenu = NSMenu()

        // Add New Feed
        let addFeedItem = NSMenuItem(
            title: "New Feed",
            action: #selector(addNewFeed),
            keyEquivalent: ""
        )
        addFeedItem.target = self
        dockMenu.addItem(addFeedItem)

        // Add New Folder
        let addFolderItem = NSMenuItem(
            title: "New Folder",
            action: #selector(addNewFolder),
            keyEquivalent: ""
        )
        addFolderItem.target = self
        dockMenu.addItem(addFolderItem)

        dockMenu.addItem(NSMenuItem.separator())

        // Refresh All Feeds
        let refreshItem = NSMenuItem(
            title: "Refresh All Feeds",
            action: #selector(refreshFeeds),
            keyEquivalent: ""
        )
        refreshItem.target = self
        dockMenu.addItem(refreshItem)

        // Mark All as Read
        let markAllReadItem = NSMenuItem(
            title: "Mark All as Read",
            action: #selector(markAllRead),
            keyEquivalent: ""
        )
        markAllReadItem.target = self
        dockMenu.addItem(markAllReadItem)

        dockMenu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(showSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        dockMenu.addItem(settingsItem)

        return dockMenu
    }

    @objc private func addNewFeed() {
        NotificationCenter.default.post(name: .addNewFeed, object: nil)
    }

    @objc private func addNewFolder() {
        NotificationCenter.default.post(name: .addNewFolder, object: nil)
    }

    @objc private func refreshFeeds() {
        NotificationCenter.default.post(name: .refreshAllFeeds, object: nil)
    }

    @objc private func markAllRead() {
        NotificationCenter.default.post(name: .markAllAsRead, object: nil)
    }

    @objc private func showSettings() {
        NotificationCenter.default.post(name: .showSettings, object: nil)
    }
}
