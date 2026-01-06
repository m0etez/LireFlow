import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var storeService: StoreService
    @ObservedObject private var configService = ConfigService.shared
    @Query(sort: \Folder.order) private var folders: [Folder]
    @Query private var feeds: [Feed]
    @Query private var articles: [Article]
    @Query(sort: \ReadingList.createdAt) private var readingLists: [ReadingList]
    
    @StateObject private var feedService = FeedService()
    
    @State private var selectedSidebarItem: SidebarItem? = .all
    @State private var selectedArticle: Article?
    @State private var searchText = ""
    @State private var showingAddFeed = false
    @State private var showingAddFolder = false
    @State private var showingAddReadingList = false
    @State private var showingSettings = false
    @State private var showingOnboarding = false
    @State private var showingUpgrade = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    private var currentTheme: AppTheme {
        configService.config.selectedTheme
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
                showingAddReadingList: $showingAddReadingList,
                onRefresh: {
                    await feedService.refreshAllFeeds(feeds: feeds, in: modelContext)
                },
                isReading: selectedArticle != nil,
                isRefreshing: feedService.isRefreshing
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } content: {
            ArticleListView(
                articles: filteredArticles,
                selectedArticle: $selectedArticle,
                searchText: $searchText,
                onRefresh: {
                    await feedService.refreshAllFeeds(feeds: feeds, in: modelContext)
                }
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            if let article = selectedArticle {
                ArticleDetailView(article: article) {
                    selectedArticle = nil
                }
            } else {
                EmptyDetailView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                #if os(iOS)
                if selectedArticle == nil {
                    toolbarButtons
                }
                #else
                toolbarButtons
                #endif
            }
        }
        .sheet(isPresented: $showingAddFeed) {
            AddFeedSheet(folders: folders)
        }
        .sheet(isPresented: $showingAddFolder) {
            AddFolderSheet()
        }
        .sheet(isPresented: $showingAddReadingList) {
            AddReadingListSheet()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        #if os(macOS)
        .sheet(isPresented: $showingOnboarding) {
            OnboardingSheet()
        }
        #else
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingSheet()
        }
        #endif
        .sheet(isPresented: $showingUpgrade) {
            UpgradeSheet()
        }
        .onAppear {
            seedDefaultFeedsIfNeeded()
            updateBadgeCount()
            checkOnboarding()
            currentTheme.apply()
        }
        .onChange(of: articles) {
            updateBadgeCount()
        }
        .onChange(of: configService.config.selectedTheme) { _, newTheme in
            newTheme.apply()
        }
        .onChange(of: selectedArticle) { _, newValue in
            NotificationCenter.default.post(
                name: .articleSelectionChanged,
                object: nil,
                userInfo: ["isReading": newValue != nil]
            )
        }
        .onChange(of: feeds) { _, _ in
            // Reset selection if selected feed no longer exists
            if case .feed(let feed) = selectedSidebarItem {
                if !feeds.contains(where: { $0.id == feed.id }) &&
                   !folders.flatMap({ $0.feeds }).contains(where: { $0.id == feed.id }) {
                    selectedSidebarItem = .all
                }
            }
        }
        .onChange(of: folders) { _, _ in
            // Reset selection if selected folder no longer exists
            if case .folder(let folder) = selectedSidebarItem {
                if !folders.contains(where: { $0.id == folder.id }) {
                    selectedSidebarItem = .all
                }
            }
        }
        .applyTheme(currentTheme)
        .applyTheme(currentTheme)
        .transform(attachSheetNotifications)
        .transform(attachActionNotifications)
    }

    private func attachSheetNotifications(_ view: some View) -> some View {
        view
            .onReceive(NotificationCenter.default.publisher(for: .addNewFeed)) { _ in showingAddFeed = true }
            .onReceive(NotificationCenter.default.publisher(for: .addNewFolder)) { _ in showingAddFolder = true }
            .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in showingSettings = true }
            .onReceive(NotificationCenter.default.publisher(for: .exportToJSON)) { _ in showingSettings = true }
            .onReceive(NotificationCenter.default.publisher(for: .exportToOPML)) { _ in showingSettings = true }
            .onReceive(NotificationCenter.default.publisher(for: .importFromJSON)) { _ in showingSettings = true }
            .onReceive(NotificationCenter.default.publisher(for: .importFromOPML)) { _ in showingSettings = true }
    }

    private func attachActionNotifications(_ view: some View) -> some View {
        view
            .onReceive(NotificationCenter.default.publisher(for: .refreshAllFeeds)) { _ in
                Task { await feedService.refreshAllFeeds(feeds: feeds, in: modelContext) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .nextArticle)) { _ in navigateToNextArticle() }
            .onReceive(NotificationCenter.default.publisher(for: .previousArticle)) { _ in navigateToPreviousArticle() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleRead)) { _ in toggleCurrentArticleRead() }
            .onReceive(NotificationCenter.default.publisher(for: .markAllAsRead)) { _ in markAllArticlesAsRead() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleStar)) { _ in toggleCurrentArticleStar() }
            .onReceive(NotificationCenter.default.publisher(for: .openInBrowser)) { _ in openCurrentArticleInBrowser() }
    }

    private var toolbarButtons: some View {
        Group {
            Button {
                Task {
                    await feedService.refreshAllFeeds(feeds: feeds, in: modelContext)
                }
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
                showingAddFeed = true
            } label: {
                Image(systemName: "plus")
            }
            .help("Add new feed")
        }
    }


    private func updateBadgeCount() {
        let unreadCount = articles.filter { !$0.isRead }.count
        PlatformApplication.setBadgeCount(unreadCount)
    }
    
    private var filteredArticles: [Article] {
        var result: [Article]

        switch selectedSidebarItem {
        case .all:
            result = articles.filter { !$0.isArchived }
        case .unread:
            result = articles.filter { !$0.isRead && !$0.isArchived }
        case .starred:
            result = articles.filter { $0.isStarred && !$0.isArchived }
        case .archived:
            result = articles.filter { $0.isArchived }
        case .folder(let folder):
            // Safe access to folder feeds - check if folder still exists
            guard folders.contains(where: { $0.id == folder.id }) else {
                return articles.filter { !$0.isArchived }
            }
            result = folder.feeds.flatMap { $0.articles }.filter { !$0.isArchived }
        case .feed(let feed):
            // Validate feed still exists
            guard feeds.contains(where: { $0.id == feed.id }) ||
                  folders.flatMap({ $0.feeds }).contains(where: { $0.id == feed.id }) else {
                return articles.filter { !$0.isArchived }
            }
            result = feed.articles.filter { !$0.isArchived }
        case .readingList(let readingList):
            // Validate reading list still exists
            guard readingLists.contains(where: { $0.id == readingList.id }) else {
                return articles.filter { !$0.isArchived }
            }
            result = readingList.articles.filter { !$0.isArchived }
        case .none:
            result = articles.filter { !$0.isArchived }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.plainTextSummary.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result.sorted { $0.publishedDate > $1.publishedDate }
    }
    


    private func navigateToNextArticle() {
        guard let currentArticle = selectedArticle else {
            // Select first article if none selected
            selectedArticle = filteredArticles.first
            return
        }

        if let currentIndex = filteredArticles.firstIndex(where: { $0.id == currentArticle.id }),
           currentIndex + 1 < filteredArticles.count {
            selectedArticle = filteredArticles[currentIndex + 1]
        }
    }

    private func navigateToPreviousArticle() {
        guard let currentArticle = selectedArticle else {
            // Select last article if none selected
            selectedArticle = filteredArticles.last
            return
        }

        if let currentIndex = filteredArticles.firstIndex(where: { $0.id == currentArticle.id }),
           currentIndex > 0 {
            selectedArticle = filteredArticles[currentIndex - 1]
        }
    }

    private func toggleCurrentArticleRead() {
        guard let article = selectedArticle else { return }
        article.isRead.toggle()
        try? modelContext.save()
    }

    private func markAllArticlesAsRead() {
        for article in filteredArticles where !article.isRead {
            article.isRead = true
        }
        try? modelContext.save()
    }

    private func toggleCurrentArticleStar() {
        guard let article = selectedArticle else { return }
        article.isStarred.toggle()
        try? modelContext.save()
    }

    private func openCurrentArticleInBrowser() {
        guard let article = selectedArticle,
              let url = URL(string: article.url) else { return }
        PlatformApplication.openURL(url)
    }
    
    private func seedDefaultFeedsIfNeeded() {
        // No default feeds - start with empty app
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
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning"
        } else if hour < 18 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            Text("\(greeting), what would you like to read?")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.platformTertiaryBackground)
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
