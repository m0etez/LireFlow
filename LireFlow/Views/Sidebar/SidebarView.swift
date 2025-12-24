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
    @Query private var allArticles: [Article]
    
    // Config service for file-based settings
    @StateObject private var configService = ConfigService.shared
    
    // Rename folder state
    @State private var showingRenameFolder = false
    @State private var folderToRename: Folder?
    @State private var newFolderName = ""
    
    private var appearanceIcon: String {
        configService.config.isDarkMode ? "moon.fill" : "sun.max.fill"
    }
    
    private func toggleAppearance() {
        configService.config.isDarkMode.toggle()
        applyAppearance()
    }
    
    private func applyAppearance() {
        let appearance = configService.config.isDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        NSApp.appearance = appearance
        for window in NSApplication.shared.windows {
            window.appearance = appearance
        }
    }
    
    var body: some View {
        List(selection: $selectedItem) {
            // Weather
            if configService.config.showWeather {
                Section {
                    WeatherWidget()
                }
            }

            // Smart Folders
            Section {
                SidebarRow(
                    icon: "tray.full",
                    title: "All Articles",
                    count: allArticles.count,
                    showCount: configService.config.showUnreadCount,
                    color: .blue
                )
                .tag(SidebarItem.all)

                SidebarRow(
                    icon: "circle.fill",
                    title: "Unread",
                    count: allArticles.filter { !$0.isRead }.count,
                    showCount: configService.config.showUnreadCount,
                    color: .orange
                )
                .tag(SidebarItem.unread)

                SidebarRow(
                    icon: "star.fill",
                    title: "Starred",
                    count: allArticles.filter { $0.isStarred }.count,
                    showCount: configService.config.showUnreadCount,
                    color: .yellow
                )
                .tag(SidebarItem.starred)
            }
            
            // User Folders
            Section("Folders") {
                ForEach(folders) { folder in
                    FolderRow(folder: folder, selectedItem: $selectedItem, showCount: configService.config.showUnreadCount)
                        .contextMenu {
                            Button {
                                folderToRename = folder
                                newFolderName = folder.name
                                showingRenameFolder = true
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button("Delete", role: .destructive) {
                                deleteFolder(folder)
                            }
                        }
                }
                .onDelete(perform: deleteFolders)
                
                Button {
                    showingAddFolder = true
                } label: {
                    Label("New Folder", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Uncategorized Feeds
            if !feeds.isEmpty {
                Section("Feeds") {
                    ForEach(feeds) { feed in
                        FeedRow(feed: feed, showCount: configService.config.showUnreadCount)
                            .tag(SidebarItem.feed(feed))
                            .contextMenu {
                                // Move to folder
                                Menu("Move to Folder") {
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
                
                Button {
                    showingAddReadingList = true
                } label: {
                    Label("New Reading List", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    showingAddFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("New Folder")
                
                Button {
                    toggleAppearance()
                } label: {
                    Image(systemName: appearanceIcon)
                        .font(.system(size: 14))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .help("Toggle Appearance")
                
                Spacer()
                
                Button {
                    showingAddFeed = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .help("Add Feed")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            applyAppearance()
        }
        .alert("Rename Folder", isPresented: $showingRenameFolder) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                renameFolder()
            }
        } message: {
            Text("Enter a new name for the folder")
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
    let count: Int
    let showCount: Bool
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)

            Text(title)
                .lineLimit(1)

            Spacer()

            if showCount && count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Folder Row

struct FolderRow: View {
    let folder: Folder
    @Binding var selectedItem: SidebarItem?
    let showCount: Bool
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(folder.feeds) { feed in
                FeedRow(feed: feed, showCount: showCount)
                    .tag(SidebarItem.feed(feed))
                    .padding(.leading, 8)
            }
        } label: {
            HStack {
                Image(systemName: folder.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text(folder.name)
                    .lineLimit(1)

                Spacer()

                if showCount && folder.unreadCount > 0 {
                    Text("\(folder.unreadCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
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
        HStack {
            Image(systemName: readingList.icon)
                .font(.system(size: 14))
                .foregroundStyle(.cyan)
                .frame(width: 20)

            Text(readingList.name)
                .lineLimit(1)

            Spacer()

            if showCount && readingList.articleCount > 0 {
                Text("\(readingList.articleCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Feed Row

struct FeedRow: View {
    let feed: Feed
    let showCount: Bool

    var body: some View {
        HStack {
            FeedIcon(url: feed.iconURL, feedURL: feed.url, websiteURL: feed.websiteURL)
                .frame(width: 18, height: 18)
                .opacity(feed.isHealthy ? 1.0 : 0.5)

            Text(feed.title)
                .lineLimit(1)
                .foregroundStyle(feed.isHealthy ? .primary : .secondary)

            if !feed.isHealthy {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .help(feed.healthStatus)
            }

            Spacer()

            if showCount && feed.unreadCount > 0 {
                Text("\(feed.unreadCount)")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Feed Icon

struct FeedIcon: View {
    let url: String?
    var feedURL: String? = nil  // The feed's URL for fallback
    var websiteURL: String? = nil  // The actual website URL (preferred for favicon)
    
    // Google's favicon service - reliable fallback
    private var faviconURL: URL? {
        // First try the explicit icon URL
        if let urlString = url, let iconURL = URL(string: urlString) {
            return iconURL
        }
        
        // Try websiteURL first (more likely to have the correct favicon)
        if let websiteURLString = websiteURL,
           let websiteURL = URL(string: websiteURLString),
           let host = websiteURL.host {
            return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")
        }
        
        // Otherwise try to get favicon from the feed's domain
        if let feedURLString = feedURL,
           let feedURL = URL(string: feedURLString),
           let host = feedURL.host {
            // Use Google's favicon service
            return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")
        }
        
        return nil
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
                    ProgressView()
                        .controlSize(.small)
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
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "dot.radiowaves.up.forward")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

