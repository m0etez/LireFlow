import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Query(filter: #Predicate<Article> { !$0.isRead },
           sort: \Article.publishedDate,
           order: .reverse)
    private var unreadArticles: [Article]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LireFlow")
                        .font(.headline)
                    Text("\(unreadArticles.count) unread")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    NotificationCenter.default.post(name: .refreshAllFeeds, object: nil)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh All Feeds")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Divider()
            
            // Recent Articles
            if unreadArticles.isEmpty {
                ContentUnavailableView("No Unread Articles", systemImage: "tray")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(unreadArticles.prefix(10)) { article in
                            MenuBarArticleRow(article: article)
                        }
                    }
                }
            }
            
            Divider()
            
            // Footer Actions
            HStack(spacing: 12) {
                Button {
                    markAllAsRead()
                } label: {
                    Text("Mark All as Read")
                }
                .buttonStyle(.borderless)
                .disabled(unreadArticles.isEmpty)
                
                Spacer()
                
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title.contains("LireFlow") || $0.isKeyWindow }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                } label: {
                    Text("Open LireFlow")
                }
                .buttonStyle(.borderless)
            }
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 320, height: 400)
    }
    
    private func markAllAsRead() {
        markRead(unreadArticles, in: modelContext)
    }
}

// MARK: - Menu Bar Article Row

struct MenuBarArticleRow: View {
    let article: Article
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Button {
            article.isRead = true
            try? modelContext.save()
            
            // Open main app and navigate to article
            NSApp.activate(ignoringOtherApps: true)
            NotificationCenter.default.post(name: .openArticle, object: article.id)
        } label: {
            HStack(spacing: 10) {
                // Feed icon
                if let feed = article.feed {
                    FeedIcon(url: feed.iconURL, feedURL: feed.url, websiteURL: feed.websiteURL)
                        .frame(width: 16, height: 16)
                } else {
                    DefaultFeedIcon()
                        .frame(width: 16, height: 16)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(article.displayTitle)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 4) {
                        if let feed = article.feed {
                            Text(feed.title)
                                .lineLimit(1)
                        }
                        Text("•")
                        Text(article.publishedDate, style: .relative)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.001)) // Hover area
    }
}
