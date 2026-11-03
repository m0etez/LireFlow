import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    let folders: [Folder]
    let feeds: [Feed]
    let readingLists: [ReadingList]
    @Binding var showingAddFeed: Bool
    @Binding var showingAddFolder: Bool
    @Binding var showingAddReadingList: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Article> { !$0.isRead }) private var unreadArticles: [Article]

    private var unreadCount: Int { unreadArticles.count }
    
    // Config service for file-based settings
    @StateObject private var configService = ConfigService.shared
    
    // Rename folder state
    @State private var showingRenameFolder = false
    @State private var folderToRename: Folder?
    @State private var newFolderName = ""

    // Rename feed state
    @State private var showingRenameFeed = false
    @State private var feedToRename: Feed?
    @State private var newFeedName = ""

    /// Whether the app renders dark right now (explicit theme, or the system setting for .system)
    private var isDark: Bool {
        let appearance = configService.config.selectedTheme.nsAppearance ?? NSApp.effectiveAppearance
        return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private var appearanceIcon: String {
        isDark ? "moon.fill" : "sun.max.fill"
    }

    /// Quick light/dark switch. Goes through the theme setting (applied by ContentView),
    /// so there's a single source of truth for appearance.
    private func toggleAppearance() {
        configService.config.selectedTheme = isDark ? .light : .dark
    }

    var body: some View {
        List(selection: $selectedItem) {
            // Smart Folders
            Section {
                SidebarRow(
                    icon: "tray.full",
                    title: String(localized: "All Articles"),
                    count: unreadCount,
                    showCount: configService.config.showUnreadCount
                )
                .tag(SidebarItem.all)
                .contextMenu {
                    Button("Mark All as Read") { markRead(unreadArticles, in: modelContext) }
                }

                SidebarRow(icon: "circle.inset.filled", title: String(localized: "Unread"))
                    .tag(SidebarItem.unread)
                    .contextMenu {
                        Button("Mark All as Read") { markRead(unreadArticles, in: modelContext) }
                    }

                SidebarRow(icon: "star", title: String(localized: "Starred"))
                    .tag(SidebarItem.starred)

                SidebarRow(icon: "archivebox", title: String(localized: "Archived"))
                    .tag(SidebarItem.archived)
            }

            // User Folders
            Section("Folders") {
                ForEach(folders) { folder in
                    FolderRow(
                        folder: folder,
                        allFolders: folders,
                        selectedItem: $selectedItem,
                        showCount: configService.config.showUnreadCount,
                        feedToRename: $feedToRename,
                        newFeedName: $newFeedName,
                        showingRenameFeed: $showingRenameFeed,
                        onRenameFolder: {
                            folderToRename = folder
                            newFolderName = folder.name
                            showingRenameFolder = true
                        },
                        onDeleteFolder: {
                            deleteFolder(folder)
                        }
                    )
                }
                .onDelete(perform: deleteFolders)

                // The + menu below covers this once there's something here
                if folders.isEmpty {
                    Button {
                        showingAddFolder = true
                    } label: {
                        Label("New Folder", systemImage: "plus")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Uncategorized Feeds
            if !feeds.isEmpty {
                Section("Feeds") {
                    ForEach(feeds) { feed in
                        FeedRow(feed: feed, showCount: configService.config.showUnreadCount)
                            .tag(SidebarItem.feed(feed))
                            .contextMenu {
                                Button("Mark All as Read") {
                                    markRead(feed.articles, in: modelContext)
                                }

                                Divider()

                                Button {
                                    feedToRename = feed
                                    newFeedName = feed.title
                                    showingRenameFeed = true
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }

                                Divider()

                                // Move to folder
                                Menu("Move to...") {
                                    Button("None (Remove from folder)") {
                                        moveFeed(feed, to: nil)
                                    }
                                    
                                    Divider()
                                    
                                    ForEach(folders) { folder in
                                        Button(folder.name) {
                                            moveFeed(feed, to: folder)
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                Button("Delete", role: .destructive) {
                                    deleteFeed(feed)
                                }
                            }
                    }
                    .onDelete(perform: deleteFeeds)
                }
            }
            
            // Reading Lists
            Section("Reading Lists") {
                ForEach(readingLists) { readingList in
                    ReadingListRow(readingList: readingList, showCount: configService.config.showUnreadCount)
                        .tag(SidebarItem.readingList(readingList))
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                deleteReadingList(readingList)
                            }
                        }
                }
                
                if readingLists.isEmpty {
                    Button {
                        showingAddReadingList = true
                    } label: {
                        Label("New Reading List", systemImage: "plus")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Menu {
                    Button("New Feed…") { showingAddFeed = true }
                    Button("New Folder…") { showingAddFolder = true }
                    Button("New Reading List…") { showingAddReadingList = true }
                } label: {
                    Image(systemName: "plus")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Add a feed, folder or reading list")

                Spacer()

                Button(action: toggleAppearance) {
                    Image(systemName: appearanceIcon)
                }
                .buttonStyle(.borderless)
                .help(isDark ? "Switch to light appearance" : "Switch to dark appearance")
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .alert("Rename Folder", isPresented: $showingRenameFolder) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                renameFolder()
            }
        } message: {
            Text("Enter a new name for the folder")
        }
        .alert("Rename Feed", isPresented: $showingRenameFeed) {
            TextField("Feed Name", text: $newFeedName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                renameFeed()
            }
        } message: {
            Text("Enter a new name for the feed")
        }
    }
    
    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(folders[index])
        }
        try? modelContext.save()
    }
    
    private func deleteFolder(_ folder: Folder) {
        modelContext.delete(folder)
        try? modelContext.save()
    }
    
    private func renameFolder() {
        guard let folder = folderToRename, !newFolderName.isEmpty else { return }
        folder.name = newFolderName
        try? modelContext.save()
        folderToRename = nil
        newFolderName = ""
    }

    private func renameFeed() {
        guard let feed = feedToRename, !newFeedName.isEmpty else { return }
        feed.title = newFeedName
        try? modelContext.save()
        feedToRename = nil
        newFeedName = ""
    }

    private func deleteFeeds(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(feeds[index])
        }
        try? modelContext.save()
    }
    
    private func deleteFeed(_ feed: Feed) {
        modelContext.delete(feed)
        try? modelContext.save()
    }
    
    private func moveFeed(_ feed: Feed, to folder: Folder?) {
        feed.folder = folder
        try? modelContext.save()
    }
    
    private func deleteReadingList(_ readingList: ReadingList) {
        modelContext.delete(readingList)
        try? modelContext.save()
    }
}

// MARK: - Sidebar Row

struct SidebarRow: View {
    let icon: String
    let title: String
    var count: Int = 0
    var showCount: Bool = false

    var body: some View {
        Label(title, systemImage: icon)
            .badge(showCount ? count : 0)
    }
}

// MARK: - Folder Row

/// Marks articles read and saves. Shared by the sidebar, toolbar, menus and menu bar popover.
@MainActor
func markRead(_ articles: some Sequence<Article>, in context: ModelContext) {
    for article in articles where !article.isRead {
        article.isRead = true
    }
    try? context.save()
}

struct FolderRow: View {
    @Environment(\.modelContext) private var modelContext
    let folder: Folder
    let allFolders: [Folder]
    @Binding var selectedItem: SidebarItem?
    let showCount: Bool
    @Binding var feedToRename: Feed?
    @Binding var newFeedName: String
    @Binding var showingRenameFeed: Bool
    var onRenameFolder: () -> Void
    var onDeleteFolder: () -> Void
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(folder.feeds) { feed in
                FeedRow(feed: feed, showCount: showCount)
                    .tag(SidebarItem.feed(feed))
                    .padding(.leading, 8)
                    .contextMenu {
                        Button("Mark All as Read") {
                            markRead(feed.articles, in: modelContext)
                        }

                        Divider()

                        Button {
                            feedToRename = feed
                            newFeedName = feed.title
                            showingRenameFeed = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Divider()

                        // Move to folder
                        Menu("Move to...") {
                            Button("None (Remove from folder)") {
                                feed.folder = nil
                                try? modelContext.save()
                            }
                            
                            Divider()
                            
                            ForEach(allFolders.filter { $0.id != folder.id }) { targetFolder in
                                Button(targetFolder.name) {
                                    feed.folder = targetFolder
                                    try? modelContext.save()
                                }
                            }
                        }

                        Divider()

                        Button("Delete", role: .destructive) {
                            modelContext.delete(feed)
                            try? modelContext.save()
                        }
                    }
            }
        } label: {
            Label(folder.name, systemImage: folder.icon)
                .badge(showCount ? folder.unreadCount : 0)
            .contextMenu {
                Button("Mark All as Read") {
                    markRead(folder.feeds.flatMap(\.articles), in: modelContext)
                }

                Divider()

                Button {
                    onRenameFolder()
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    onDeleteFolder()
                }
            }
        }
        .tag(SidebarItem.folder(folder))
    }
}

// MARK: - Reading List Row

struct ReadingListRow: View {
    let readingList: ReadingList
    let showCount: Bool

    var body: some View {
        Label(readingList.name, systemImage: readingList.icon)
            .badge(showCount ? readingList.articleCount : 0)
    }
}

// MARK: - Feed Row

struct FeedRow: View {
    let feed: Feed
    let showCount: Bool

    var body: some View {
        Label {
            HStack(spacing: 4) {
                Text(feed.title)
                    .foregroundStyle(feed.isHealthy ? .primary : .secondary)
                if !feed.isHealthy {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .help(feed.healthStatus)
                }
            }
        } icon: {
            FeedIcon(url: feed.iconURL, feedURL: feed.url, websiteURL: feed.websiteURL)
                .frame(width: 16, height: 16)
                .opacity(feed.isHealthy ? 1.0 : 0.5)
        }
        .lineLimit(1)
        .badge(showCount ? feed.unreadCount : 0)
    }
}

// MARK: - Feed Icon

struct FeedIcon: View {
    let url: String?
    var feedURL: String? = nil  // The feed's URL for fallback
    var websiteURL: String? = nil  // The actual website URL (preferred for favicon)
    
    /// The site's own favicon. ponytail: /favicon.ico only; sites that declare the icon
    /// elsewhere get the generic icon. Parse <link rel="icon"> if that's too many.
    private var faviconURL: URL? {
        if let urlString = url, let iconURL = URL(string: urlString) {
            return iconURL
        }
        let pageURL = websiteURL.flatMap(URL.init(string:)) ?? feedURL.flatMap(URL.init(string:))
        guard let host = pageURL?.host else { return nil }
        return URL(string: "https://\(host)/favicon.ico")
    }

    var body: some View {
        if let iconURL = faviconURL {
            AsyncImage(url: iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    DefaultFeedIcon()
                case .empty:
                    DefaultFeedIcon()
                @unknown default:
                    DefaultFeedIcon()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            DefaultFeedIcon()
        }
    }
}

struct DefaultFeedIcon: View {
    var body: some View {
        Image(systemName: "dot.radiowaves.up.forward")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
            .padding(1)
    }
}

