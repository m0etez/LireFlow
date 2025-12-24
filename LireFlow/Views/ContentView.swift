import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
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
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
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
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .onAppear {
            setupNotificationObservers()
            seedDefaultFeedsIfNeeded()
            updateBadgeCount()
        }
        .onChange(of: articles) {
            updateBadgeCount()
        }
    }

    private func updateBadgeCount() {
        let unreadCount = articles.filter { !$0.isRead }.count
        if unreadCount > 0 {
            NSApp.dockTile.badgeLabel = "\(unreadCount)"
        } else {
            NSApp.dockTile.badgeLabel = nil
        }
    }
    
    private var filteredArticles: [Article] {
        var result: [Article]
        
        switch selectedSidebarItem {
        case .all:
            result = articles
        case .unread:
            result = articles.filter { !$0.isRead }
        case .starred:
            result = articles.filter { $0.isStarred }
        case .folder(let folder):
            result = folder.feeds.flatMap { $0.articles }
        case .feed(let feed):
            result = feed.articles
        case .readingList(let readingList):
            result = readingList.articles
        case .none:
            result = articles
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.plainTextSummary.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result.sorted { $0.publishedDate > $1.publishedDate }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(forName: .addNewFeed, object: nil, queue: .main) { _ in
            showingAddFeed = true
        }
        NotificationCenter.default.addObserver(forName: .addNewFolder, object: nil, queue: .main) { _ in
            showingAddFolder = true
        }
        NotificationCenter.default.addObserver(forName: .refreshAllFeeds, object: nil, queue: .main) { _ in
            Task {
                await feedService.refreshAllFeeds(feeds: feeds, in: modelContext)
            }
        }
        NotificationCenter.default.addObserver(forName: .showSettings, object: nil, queue: .main) { _ in
            showingSettings = true
        }
        NotificationCenter.default.addObserver(forName: .exportToJSON, object: nil, queue: .main) { _ in
            showingSettings = true
        }
        NotificationCenter.default.addObserver(forName: .exportToOPML, object: nil, queue: .main) { _ in
            showingSettings = true
        }
        NotificationCenter.default.addObserver(forName: .importFromJSON, object: nil, queue: .main) { _ in
            showingSettings = true
        }
        NotificationCenter.default.addObserver(forName: .importFromOPML, object: nil, queue: .main) { _ in
            showingSettings = true
        }

        // Keyboard shortcuts
        NotificationCenter.default.addObserver(forName: .nextArticle, object: nil, queue: .main) { _ in
            navigateToNextArticle()
        }
        NotificationCenter.default.addObserver(forName: .previousArticle, object: nil, queue: .main) { _ in
            navigateToPreviousArticle()
        }
        NotificationCenter.default.addObserver(forName: .toggleRead, object: nil, queue: .main) { _ in
            toggleCurrentArticleRead()
        }
        NotificationCenter.default.addObserver(forName: .toggleStar, object: nil, queue: .main) { _ in
            toggleCurrentArticleStar()
        }
        NotificationCenter.default.addObserver(forName: .openInBrowser, object: nil, queue: .main) { _ in
            openCurrentArticleInBrowser()
        }
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
    
    private func seedDefaultFeedsIfNeeded() {
        // No default feeds - start with empty app
    }
}

// MARK: - Sidebar Item

enum SidebarItem: Hashable {
    case all
    case unread
    case starred
    case folder(Folder)
    case feed(Feed)
    case readingList(ReadingList)
}

// MARK: - Empty Detail View

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            Text("Select an article to read")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Feed.self, Article.self, Folder.self], inMemory: true)
}
