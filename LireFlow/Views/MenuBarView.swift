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
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Refresh All Feeds")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Recent Articles
            if unreadArticles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                    Text("All caught up!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
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
                    Label("Mark All Read", systemImage: "checkmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(unreadArticles.isEmpty)
                
                Spacer()
                
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.title.contains("LireFlow") || $0.isKeyWindow }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                } label: {
                    Text("Open LireFlow")
                        .font(.caption.bold())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .frame(width: 320, height: 400)
    }
    
    private func markAllAsRead() {
        for article in unreadArticles {
            article.isRead = true
        }
        try? modelContext.save()
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
                    FeedIconSmall(url: feed.iconURL, feedURL: feed.url)
                        .frame(width: 24, height: 24)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(width: 24, height: 24)
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
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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

// MARK: - Small Feed Icon

struct FeedIconSmall: View {
    let url: String?
    var feedURL: String? = nil
    
    private var faviconURL: URL? {
        if let urlString = url, let iconURL = URL(string: urlString) {
            return iconURL
        }
        if let feedURLString = feedURL,
           let feedURL = URL(string: feedURLString),
           let host = feedURL.host {
            return URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=64")
        }
        return nil
    }
    
    var body: some View {
        if let iconURL = faviconURL {
            AsyncImage(url: iconURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                default:
                    DefaultFeedIconSmall()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            DefaultFeedIconSmall()
        }
    }
}

struct DefaultFeedIconSmall: View {
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
