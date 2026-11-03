import SwiftUI
import SwiftData

struct ArticleListView: View {
    let articles: [Article]
    @Binding var selectedArticle: Article?
    @Binding var searchText: String
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReadingList.createdAt) private var readingLists: [ReadingList]
    @ObservedObject private var configService = ConfigService.shared
    
    private var currentTheme: AppTheme {
        configService.config.selectedTheme
    }
    
    var body: some View {
        Group {
            if articles.isEmpty {
                emptyState
            } else {
                // Native list: selection, keyboard focus, hover and highlight come from the platform
                List(selection: $selectedArticle) {
                    ForEach(articles) { article in
                        articleView(for: article)
                            .tag(article)
                            .contextMenu { articleContextMenu(for: article) }
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(minWidth: 280)
        .background(currentTheme.secondaryBackground)
    }

    @ViewBuilder
    private var emptyState: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            ContentUnavailableView {
                Label("No Articles", systemImage: "newspaper")
            } description: {
                Text("New articles from your feeds appear here.")
            } actions: {
                Button("Add Feed…") {
                    NotificationCenter.default.post(name: .addNewFeed, object: nil)
                }
            }
        }
    }

    @ViewBuilder
    private func articleView(for article: Article) -> some View {
        switch configService.config.articleLayout {
        case .standard:
            ArticleRow(article: article)
        case .card:
            CardArticleRow(article: article)
        case .compact:
            CompactArticleRow(article: article)
        }
    }
    
    @ViewBuilder
    private func articleContextMenu(for article: Article) -> some View {
        Menu("Save to...") {
            if readingLists.isEmpty {
                Text("No lists")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(readingLists) { readingList in
                    Button {
                        saveArticle(article, to: readingList)
                    } label: {
                        Label {
                            Text(readingList.name)
                        } icon: {
                            Image(systemName: isArticleInList(article, readingList) ? "checkmark" : readingList.icon)
                        }
                    }
                }
            }
        }
        
        if let lists = article.readingLists, !lists.isEmpty {
            Menu("Remove from list") {
                ForEach(lists) { readingList in
                    Button(readingList.name) {
                        removeArticle(article, from: readingList)
                    }
                }
            }
        }
        
        Divider()
        
        Button {
            article.isStarred.toggle()
        } label: {
            Label(article.isStarred ? "Remove from starred" : "Add to starred", systemImage: article.isStarred ? "star.slash" : "star")
        }
        
        Button {
            article.isRead.toggle()
        } label: {
            Label(article.isRead ? "Mark as unread" : "Mark as read", systemImage: article.isRead ? "circle" : "circle.fill")
        }

        Button {
            article.isArchived.toggle()
        } label: {
            Label(article.isArchived ? "Unarchive" : "Archive", systemImage: article.isArchived ? "tray.and.arrow.up" : "archivebox")
        }

        Divider()

        Button {
            copyArticleAsMarkdown(article)
        } label: {
            Label("Copy as Markdown", systemImage: "doc.on.doc")
        }
    }
    
    private func saveArticle(_ article: Article, to readingList: ReadingList) {
        var lists = article.readingLists ?? []
        guard !lists.contains(where: { $0.id == readingList.id }) else { return }
        lists.append(readingList)
        article.readingLists = lists
        try? modelContext.save()
    }
    
    private func removeArticle(_ article: Article, from readingList: ReadingList) {
        article.readingLists?.removeAll { $0.id == readingList.id }
        try? modelContext.save()
    }
    
    private func isArticleInList(_ article: Article, _ readingList: ReadingList) -> Bool {
        article.readingLists?.contains { $0.id == readingList.id } ?? false
    }

    private func copyArticleAsMarkdown(_ article: Article) {
        var markdown = ""

        // Title
        markdown += "# \(article.displayTitle)\n\n"

        // Metadata
        if let author = article.author, !author.isEmpty {
            markdown += "**Author:** \(author)\n\n"
        }
        if let feed = article.feed {
            markdown += "**Source:** \(feed.title)\n\n"
        }
        markdown += "**Date:** \(article.publishedDate.formatted(date: .long, time: .omitted))\n\n"
        markdown += "**URL:** [\(article.url)](\(article.url))\n\n"
        markdown += "---\n\n"

        // Content (convert HTML to markdown-ish)
        let content = article.content.isEmpty ? article.summary : article.content
        let strippedContent = content.strippingHTML.decodingHTMLEntities
        markdown += strippedContent

        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
    }
}

// MARK: - Shared row bits

/// Unread marker; keeps its width when read so titles stay aligned
private struct UnreadDot: View {
    let isRead: Bool
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(isRead ? Color.clear : Color.accentColor)
            .frame(width: size, height: size)
            .accessibilityLabel(isRead ? "" : String(localized: "Unread"))
    }
}

// MARK: - Article Row

struct ArticleRow: View {
    @Bindable var article: Article

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            UnreadDot(isRead: article.isRead)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let feed = article.feed {
                        Text(feed.title)
                            .lineLimit(1)
                    }
                    Spacer()
                    if article.isStarred {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .accessibilityLabel("Starred")
                    }
                    Text(article.formattedDate)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(article.displayTitle)
                    .font(.headline)
                    .fontWeight(article.isRead ? .regular : .semibold)
                    .foregroundStyle(article.isRead ? .secondary : .primary)
                    .lineLimit(2)

                if !article.plainTextSummary.isEmpty {
                    Text(article.plainTextSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Card Article Row

/// Roomier layout: source icon, longer title and summary, reading time
struct CardArticleRow: View {
    @Bindable var article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let feed = article.feed {
                    FeedIcon(url: feed.iconURL, feedURL: feed.url, websiteURL: feed.websiteURL)
                        .frame(width: 16, height: 16)
                    Text(feed.title)
                        .lineLimit(1)
                }
                Spacer()
                Text(article.formattedDate)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(article.displayTitle)
                .font(.title3)
                .fontWeight(article.isRead ? .regular : .semibold)
                .foregroundStyle(article.isRead ? .secondary : .primary)
                .lineLimit(3)

            if !article.plainTextSummary.isEmpty {
                Text(article.plainTextSummary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack(spacing: 6) {
                UnreadDot(isRead: article.isRead, size: 6)
                Text(article.readingTimeText)
                Spacer()
                if article.isStarred {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityLabel("Starred")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Compact Article Row

struct CompactArticleRow: View {
    @Bindable var article: Article

    var body: some View {
        HStack(spacing: 8) {
            UnreadDot(isRead: article.isRead, size: 6)

            Text(article.displayTitle)
                .fontWeight(article.isRead ? .regular : .medium)
                .foregroundStyle(article.isRead ? .secondary : .primary)
                .lineLimit(1)

            Spacer()

            if article.isStarred {
                Image(systemName: "star.fill")
                    .imageScale(.small)
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Starred")
            }

            Group {
                if let feed = article.feed {
                    Text(feed.title)
                        .lineLimit(1)
                        .frame(maxWidth: 90, alignment: .trailing)
                }
                Text(article.formattedDate)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ArticleListView(
        articles: [],
        selectedArticle: .constant(nil),
        searchText: .constant("")
    )
}
