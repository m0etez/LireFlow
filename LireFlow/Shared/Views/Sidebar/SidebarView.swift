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
    var onRefresh: (() async -> Void)? = nil
    var isReading: Bool = false
    var isRefreshing: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allArticles: [Article]
    
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

    // Feed search
    @State private var feedSearchText = ""
    
    // Settings state
    @State private var showingSettings = false

    private var appearanceIcon: String {
        configService.config.isDarkMode ? "moon.fill" : "sun.max.fill"
    }
    
    private func toggleAppearance() {
        configService.config.isDarkMode.toggle()
        
        // Update selected theme to match
        if configService.config.isDarkMode {
             // If current theme is light-only, switch to dark
             if configService.config.selectedTheme == .light || configService.config.selectedTheme == .system {
                 configService.config.selectedTheme = .dark
             }
        } else {
             // If current theme is dark-only, switch to light
             if configService.config.selectedTheme == .dark || configService.config.selectedTheme == .system {
                 configService.config.selectedTheme = .light
             }
        }
        
        applyAppearance()
    }
    
    private func applyAppearance() {
        #if os(macOS)
        let appearance = configService.config.isDarkMode ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        NSApp.appearance = appearance
        for window in NSApplication.shared.windows {
            window.appearance = appearance
        }
        #endif
        // On iOS, appearance is handled via SwiftUI's preferredColorScheme observing configService
    }

    private var filteredFolders: [Folder] {
        guard !feedSearchText.isEmpty else { return folders }
        return folders.filter { folder in
            folder.name.localizedCaseInsensitiveContains(feedSearchText) ||
            folder.feeds.contains { $0.title.localizedCaseInsensitiveContains(feedSearchText) }
        }
    }

    private var filteredFeeds: [Feed] {
        guard !feedSearchText.isEmpty else { return feeds }
        return feeds.filter { $0.title.localizedCaseInsensitiveContains(feedSearchText) }
    }

    private var sidebarBottomBar: some View {
        HStack {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            .help("Paramètres")

            Button {
                showingAddFolder = true
            } label: {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 20)) // Increased size
            }
            .buttonStyle(.plain)
            .help("Nouveau dossier")
            
            #if os(iOS)
            Button {
                Task {
                        await onRefresh?()
                }
            } label: {
                RefreshButtonView(isRefreshing: isRefreshing)
            }
            .buttonStyle(.plain)
            #endif
            
            
            Button {
                toggleAppearance()
            } label: {
                Image(systemName: appearanceIcon)
                    .font(.system(size: 20)) // Increased size
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .help("Changer l'apparence")
            
            Spacer()
            
            Button {
                showingAddFeed = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Ajouter")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(configService.config.selectedTheme.accentColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(configService.config.selectedTheme.accentColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("Ajouter un flux")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    var body: some View {
        List(selection: $selectedItem) {
            // Weather
            if configService.config.showWeather {
                Section {
                    WeatherWidget()
                        .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                        .listRowBackground(Color.clear)
                }
            }

            // Smart Folders
            Section {
                SidebarRow(
                    icon: "tray.full",
                    title: "Tous les articles",
                    count: allArticles.count,
                    showCount: configService.config.showUnreadCount,
                    color: .blue
                )
                .tag(SidebarItem.all)

                SidebarRow(
                    icon: "circle.fill",
                    title: "Non lus",
                    count: allArticles.filter { !$0.isRead }.count,
                    showCount: configService.config.showUnreadCount,
                    color: .orange
                )
                .tag(SidebarItem.unread)

                SidebarRow(
                    icon: "star.fill",
                    title: "Favoris",
                    count: allArticles.filter { $0.isStarred }.count,
                    showCount: configService.config.showUnreadCount,
                    color: .yellow
                )
                .tag(SidebarItem.starred)

                SidebarRow(
                    icon: "archivebox",
                    title: "Archivés",
                    count: allArticles.filter { $0.isArchived }.count,
                    showCount: configService.config.showUnreadCount,
                    color: .gray
                )
                .tag(SidebarItem.archived)
            }
            
            // Feed search
            if !folders.isEmpty || !feeds.isEmpty {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        TextField("Rechercher...", text: $feedSearchText)
                            .textFieldStyle(.plain)
                        if !feedSearchText.isEmpty {
                            Button {
                                feedSearchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // User Folders
            Section("Dossiers") {
                ForEach(filteredFolders) { folder in
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
                
                Button {
                    showingAddFolder = true
                } label: {
                    Label("Nouveau dossier", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Uncategorized Feeds
            if !filteredFeeds.isEmpty {
                Section("Flux") {
                    ForEach(filteredFeeds) { feed in
                        FeedRow(feed: feed, showCount: configService.config.showUnreadCount)
                            .tag(SidebarItem.feed(feed))
                            .contextMenu {
                                Button {
                                    feedToRename = feed
                                    newFeedName = feed.title
                                    showingRenameFeed = true
                                } label: {
                                    Label("Renommer", systemImage: "pencil")
                                }

                                Divider()

                                // Move to folder
                                Menu("Déplacer vers...") {
                                    Button("Aucun (Retirer du dossier)") {
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
                                
                                Button("Supprimer", role: .destructive) {
                                    deleteFeed(feed)
                                }
                            }
                    }
                    .onDelete(perform: deleteFeeds)
                }
            }
            
            // Reading Lists
            Section("Listes de lecture") {
                ForEach(readingLists) { readingList in
                    ReadingListRow(readingList: readingList, showCount: configService.config.showUnreadCount)
                        .tag(SidebarItem.readingList(readingList))
                        .contextMenu {
                            Button("Supprimer", role: .destructive) {
                                deleteReadingList(readingList)
                            }
                        }
                }
                
                Button {
                    showingAddReadingList = true
                } label: {
                    Label("Nouvelle liste", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .safeAreaInset(edge: .bottom) {
            #if os(iOS)
            if !isReading {
                sidebarBottomBar
            }
            #else
            sidebarBottomBar
            #endif
        }
                

        .onAppear {
            applyAppearance()
        }
        .sheet(isPresented: $showingSettings) {
             SettingsSheet()
        }
        .alert("Renommer le dossier", isPresented: $showingRenameFolder) {
            TextField("Nom du dossier", text: $newFolderName)
            Button("Annuler", role: .cancel) { }
            Button("Renommer") {
                renameFolder()
            }
        } message: {
            Text("Entrez un nouveau nom pour le dossier")
        }
        .alert("Renommer le flux", isPresented: $showingRenameFeed) {
            TextField("Nom du flux", text: $newFeedName)
            Button("Annuler", role: .cancel) { }
            Button("Renommer") {
                renameFeed()
            }
        } message: {
            Text("Entrez un nouveau nom pour le flux")
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
    let count: Int
    let showCount: Bool
    let color: Color
    @State private var isHovered = false
    @ObservedObject private var configService = ConfigService.shared

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
        .contentShape(Rectangle())
        .background {
            if isHovered {
                RoundedRectangle(cornerRadius: 6)
                    .fill(configService.config.hoverColorHex.isEmpty ? Color.accentColor.opacity(0.15) : Color(hex: configService.config.hoverColorHex))
            }
        }
        .onHover { isHovered = $0 }
    }
}

// MARK: - Folder Row

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
    @State private var isHovered = false
    @ObservedObject private var configService = ConfigService.shared

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(folder.feeds) { feed in
                FeedRow(feed: feed, showCount: showCount)
                    .tag(SidebarItem.feed(feed))
                    .padding(.leading, 8)
                    .contextMenu {
                        Button {
                            feedToRename = feed
                            newFeedName = feed.title
                            showingRenameFeed = true
                        } label: {
                            Label("Renommer", systemImage: "pencil")
                        }

                        Divider()

                        // Move to folder
                        Menu("Déplacer vers...") {
                            Button("Aucun (Retirer du dossier)") {
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

                        Button("Supprimer", role: .destructive) {
                            modelContext.delete(feed)
                            try? modelContext.save()
                        }
                    }
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
            .contentShape(Rectangle())
            .background {
                if isHovered && !configService.config.hoverColorHex.isEmpty {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: configService.config.hoverColorHex))
                }
            }
            .onHover { isHovered = $0 }
            .contextMenu {
                Button {
                    onRenameFolder()
                } label: {
                    Label("Renommer", systemImage: "pencil")
                }
                
                Divider()
                
                Button("Supprimer", role: .destructive) {
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
    @State private var isHovered = false
    @ObservedObject private var configService = ConfigService.shared

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
        .contentShape(Rectangle())
        .background {
            if isHovered && !configService.config.hoverColorHex.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: configService.config.hoverColorHex))
            }
        }
        .onHover { isHovered = $0 }
    }
}

// MARK: - Feed Row

struct FeedRow: View {
    let feed: Feed
    let showCount: Bool
    @State private var isHovered = false
    @ObservedObject private var configService = ConfigService.shared

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
        .contentShape(Rectangle())
        .background {
            if isHovered && !configService.config.hoverColorHex.isEmpty {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: configService.config.hoverColorHex))
            }
        }
        .onHover { isHovered = $0 }
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

struct RefreshButtonView: View {
    let isRefreshing: Bool
    
    var body: some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 20))
                .symbolEffect(.rotate, isActive: isRefreshing)
        } else {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 20))
        }
    }
}

