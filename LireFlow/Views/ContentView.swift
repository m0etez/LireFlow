import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var storeService: StoreService
    @ObservedObject private var configService = ConfigService.shared
    @Query(sort: \Folder.order) private var folders: [Folder]
    @Query private var feeds: [Feed]
    @Query(sort: \Article.publishedDate, order: .reverse) private var articles: [Article]
    @Query(sort: \ReadingList.createdAt) private var readingLists: [ReadingList]

    @StateObject private var feedService = FeedService()

    @State private var selectedSidebarItem: SidebarItem? = .all
    @State private var selectedArticle: Article?
    @State private var searchText = ""
    @State private var showingAddFeed = false
    @State private var showingAddFolder = false
    @State private var showingAddReadingList = false
    @State private var showingOnboarding = false
    @StateObject private var backup = BackupController()
    @Environment(\.openSettings) private var openSettings
    @State private var showingUpgrade = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var currentTheme: AppTheme {
        configService.config.selectedTheme
    }

    /// Restarts the auto-refresh loop whenever its settings change
    private var refreshSchedule: String {
        "\(configService.config.backgroundRefreshEnabled)-\(configService.config.refreshIntervalMinutes)"
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedItem: $selectedSidebarItem,
                folders: folders,
                feeds: feeds.filter { $0.folder == nil },
                readingLists: readingLists,
                showingAddFeed: $showingAddFeed,
                showingAddFolder: $showingAddFolder,
                showingAddReadingList: $showingAddReadingList
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } content: {
            ArticleListView(
                articles: filteredArticles,
                selectedArticle: $selectedArticle,
                searchText: $searchText
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            // A deleted article (feed removed, cleanup) must never reach the detail view
            if let article = selectedArticle, !article.isDeleted, article.modelContext != nil {
                ArticleDetailView(article: article)
                    .id(article.id)  // each article opens at the top, with fresh fetch state
            } else {
                EmptyDetailView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task { await refreshAll() }
                } label: {
                    if feedService.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .help("Refresh all feeds")
                .disabled(feedService.isRefreshing)

                Button {
                    markAllArticlesAsRead()
                } label: {
                    Label("Mark All as Read", systemImage: "checkmark.circle")
                }
                .help("Mark every article in this list as read (⇧⌘A)")

                Button {
                    showingAddFeed = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add new feed")
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search articles")
        .sheet(isPresented: $showingAddFeed) {
            AddFeedSheet(folders: folders)
        }
        .sheet(isPresented: $showingAddFolder) {
            AddFolderSheet()
        }
        .sheet(isPresented: $showingAddReadingList) {
            AddReadingListSheet()
        }
        .backupAlert(backup)
        .sheet(isPresented: $showingOnboarding) {
            OnboardingSheet()
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeSheet()
        }
        .onAppear {
            updateBadgeCount()
            checkOnboarding()
            currentTheme.apply()
        }
        .task {
            // Refresh once at launch
            if configService.config.backgroundRefreshEnabled {
                await refreshAll()
            }
        }
        .task(id: refreshSchedule) {
            // Then every refresh interval, while background refresh is on
            guard configService.config.backgroundRefreshEnabled else { return }
            while !Task.isCancelled {
                let interval = max(configService.config.refreshIntervalMinutes, 5)
                try? await Task.sleep(for: .seconds(interval * 60))
                guard !Task.isCancelled else { return }
                await refreshAll()
            }
        }
        .onChange(of: articles) {
            updateBadgeCount()
            if let article = selectedArticle, article.isDeleted || article.modelContext == nil {
                selectedArticle = nil
            }
        }
        .onChange(of: feeds) { dropDeletedSidebarSelection() }
        .onChange(of: folders) { dropDeletedSidebarSelection() }
        .onChange(of: readingLists) { dropDeletedSidebarSelection() }
        .onChange(of: configService.config.selectedTheme) { _, newTheme in
            newTheme.apply()
        }
        .applyTheme(currentTheme)
        .transform(attachSheetNotifications)
        .transform(attachActionNotifications)
    }

    private func runBackup(_ action: BackupAction) {
        Task { await backup.run(action, in: modelContext) }
    }

    private func attachSheetNotifications(_ view: some View) -> some View {
        view
            .onReceive(NotificationCenter.default.publisher(for: .addNewFeed)) { _ in showingAddFeed = true }
            .onReceive(NotificationCenter.default.publisher(for: .addNewFolder)) { _ in showingAddFolder = true }
            .onReceive(NotificationCenter.default.publisher(for: .addNewReadingList)) { _ in showingAddReadingList = true }
            .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in openSettings() }
            .onReceive(NotificationCenter.default.publisher(for: .exportToJSON)) { _ in runBackup(.exportJSON) }
            .onReceive(NotificationCenter.default.publisher(for: .exportToOPML)) { _ in runBackup(.exportOPML) }
            .onReceive(NotificationCenter.default.publisher(for: .importFromJSON)) { _ in runBackup(.importJSON) }
            .onReceive(NotificationCenter.default.publisher(for: .importFromOPML)) { _ in runBackup(.importOPML) }
    }

    private func attachActionNotifications(_ view: some View) -> some View {
        view
            .onReceive(NotificationCenter.default.publisher(for: .refreshAllFeeds)) { _ in
                Task { await refreshAll() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .nextArticle)) { _ in navigateToNextArticle() }
            .onReceive(NotificationCenter.default.publisher(for: .previousArticle)) { _ in navigateToPreviousArticle() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleRead)) { _ in toggleCurrentArticleRead() }
            .onReceive(NotificationCenter.default.publisher(for: .markAllAsRead)) { _ in markAllArticlesAsRead() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleStar)) { _ in toggleCurrentArticleStar() }
            .onReceive(NotificationCenter.default.publisher(for: .openInBrowser)) { _ in openCurrentArticleInBrowser() }
    }

    /// Fetches the feed list fresh, so a long-running refresh loop never works on a stale snapshot
    private func refreshAll() async {
        let currentFeeds = (try? modelContext.fetch(FetchDescriptor<Feed>())) ?? feeds
        await feedService.refreshAllFeeds(feeds: currentFeeds, in: modelContext)
    }

    private func dropDeletedSidebarSelection() {
        let isGone: Bool
        switch selectedSidebarItem {
        case .folder(let folder): isGone = folder.isDeleted || folder.modelContext == nil
        case .feed(let feed): isGone = feed.isDeleted || feed.modelContext == nil
        case .readingList(let list): isGone = list.isDeleted || list.modelContext == nil
        default: isGone = false
        }
        if isGone {
            selectedSidebarItem = .all
        }
    }

    private func updateBadgeCount() {
        let unreadCount = articles.lazy.filter { !$0.isRead }.count
        NSApp.dockTile.badgeLabel = unreadCount > 0 ? "\(unreadCount)" : nil
    }

    private var filteredArticles: [Article] {
        var result: [Article]
        var needsSort = false  // `articles` is already newest-first; relationship arrays aren't

        switch selectedSidebarItem {
        case .all, .none:
            result = articles.filter { !$0.isArchived }
        case .unread:
            result = articles.filter { !$0.isRead && !$0.isArchived }
        case .starred:
            result = articles.filter { $0.isStarred && !$0.isArchived }
        case .archived:
            result = articles.filter { $0.isArchived }
        case .folder(let folder):
            result = folder.feeds.flatMap { $0.articles }.filter { !$0.isArchived }
            needsSort = true
        case .feed(let feed):
            result = feed.articles.filter { !$0.isArchived }
            needsSort = true
        case .readingList(let readingList):
            result = readingList.articles.filter { !$0.isArchived }
            needsSort = true
        }

        if !searchText.isEmpty {
            // ponytail: matches the raw summary, not the HTML-stripped one (that ran a regex per
            // article per keystroke); tag names can rarely match. Index plain text if that matters.
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.summary.localizedCaseInsensitiveContains(searchText)
            }
        }

        return needsSort ? result.sorted { $0.publishedDate > $1.publishedDate } : result
    }

    private func navigateToNextArticle() {
        let list = filteredArticles
        guard let currentArticle = selectedArticle else {
            // Select first article if none selected
            selectedArticle = list.first
            return
        }

        if let currentIndex = list.firstIndex(where: { $0.id == currentArticle.id }),
           currentIndex + 1 < list.count {
            selectedArticle = list[currentIndex + 1]
        }
    }

    private func navigateToPreviousArticle() {
        let list = filteredArticles
        guard let currentArticle = selectedArticle else {
            // Select last article if none selected
            selectedArticle = list.last
            return
        }

        if let currentIndex = list.firstIndex(where: { $0.id == currentArticle.id }),
           currentIndex > 0 {
            selectedArticle = list[currentIndex - 1]
        }
    }

    private func toggleCurrentArticleRead() {
        guard let article = selectedArticle else { return }
        article.isRead.toggle()
        try? modelContext.save()
    }

    private func markAllArticlesAsRead() {
        markRead(filteredArticles, in: modelContext)
    }

    private func toggleCurrentArticleStar() {
        guard let article = selectedArticle else { return }
        article.isStarred.toggle()
        try? modelContext.save()
    }

    private func openCurrentArticleInBrowser() {
        guard let article = selectedArticle,
              let url = URL(string: article.url) else { return }
        NSWorkspace.shared.open(url)
    }

    private func checkOnboarding() {
        if !ConfigService.shared.config.hasCompletedOnboarding {
            // Small delay to let the main window appear first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingOnboarding = true
            }
        }
    }
}

// MARK: - Sidebar Item

enum SidebarItem: Hashable {
    case all
    case unread
    case starred
    case archived
    case folder(Folder)
    case feed(Feed)
    case readingList(ReadingList)
}

// MARK: - Empty Detail View

struct EmptyDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "No Article Selected",
            systemImage: "doc.text",
            description: Text("Choose an article to read it here.")
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Feed.self, Article.self, Folder.self], inMemory: true)
}

extension View {
    func transform<Content: View>(_ transform: (Self) -> Content) -> Content {
        transform(self)
    }
}
