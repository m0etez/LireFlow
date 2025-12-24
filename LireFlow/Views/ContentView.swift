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
        .onAppear {
            setupNotificationObservers()
            seedDefaultFeedsIfNeeded()
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
    }
    
    private func seedDefaultFeedsIfNeeded() {
        guard feeds.isEmpty else { return }
        
        Task {
            // Add a few starter feeds
            let starterFeeds = [
                DefaultFeeds.feeds[0], // Hacker News
                DefaultFeeds.feeds[7], // Daring Fireball
                DefaultFeeds.feeds[10] // Swift by Sundell
            ]
            
            for feedInfo in starterFeeds {
                do {
                    _ = try await feedService.addFeed(url: feedInfo.url, in: modelContext)
                } catch {
                    print("Failed to add default feed: \(error)")
                }
            }
        }
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
