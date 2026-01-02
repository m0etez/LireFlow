import SwiftUI
import SwiftData

struct ArticleListView: View {
    let articles: [Article]
    @Binding var selectedArticle: Article?
    @Binding var searchText: String
    var onRefresh: (() async -> Void)? = nil
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReadingList.createdAt) private var readingLists: [ReadingList]
    @ObservedObject private var configService = ConfigService.shared
    
    @State private var isSearchVisible = false
    
    private var currentTheme: AppTheme {
        configService.config.selectedTheme
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar (hidden by default, toggles visible)
            if isSearchVisible {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search articles...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSearchVisible = false
                            searchText = ""
                        }
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Layout picker header
            HStack {
                Text("\(articles.count) articles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Search toggle button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearchVisible.toggle()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(isSearchVisible ? currentTheme.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                
                // Layout picker
                Picker("", selection: $configService.config.articleLayout) {
                    ForEach(ArticleLayout.allCases, id: \.self) { layout in
                        Image(systemName: layout.icon)
                            .tag(layout)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Article list
            Group {
                if articles.isEmpty {
                    EmptyArticleListView(isSearching: !searchText.isEmpty)
                } else {
                    ScrollView {
                        LazyVStack(spacing: layoutSpacing) {
                            ForEach(articles, id: \.id) { article in
                                #if os(iOS)
                                NavigationLink(value: article) {
                                    articleView(for: article)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    articleContextMenu(for: article)
                                }
                                #else
                                articleView(for: article)
                                    .onTapGesture {
                                        selectedArticle = article
                                    }
                                    .contextMenu {
                                        articleContextMenu(for: article)
                                    }
                                #endif
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    #if os(iOS)
                    .navigationDestination(for: Article.self) { article in
                        ArticleDetailView(article: article) {
                            // No-op for close, navigation handles it
                        }
                    }
                    #endif
                }
            }
        }
        .frame(minWidth: 280)
        .background(currentTheme.secondaryBackground)
        .refreshable {
            await onRefresh?()
        }
    }
    
    private var layoutSpacing: CGFloat {
        switch configService.config.articleLayout {
        case .standard: return 2
        case .card: return 12
        case .compact: return 0
        }
    }
    
    @ViewBuilder
    private func articleView(for article: Article) -> some View {
        switch configService.config.articleLayout {
        case .standard:
            ArticleRow(article: article, isSelected: selectedArticle?.id == article.id)
        case .card:
            CardArticleRow(article: article, isSelected: selectedArticle?.id == article.id)
        case .compact:
            CompactArticleRow(article: article, isSelected: selectedArticle?.id == article.id)
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
        PlatformPasteboard.copyToClipboard(markdown)
    }
}

// MARK: - Empty State

struct EmptyArticleListView: View {
    let isSearching: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isSearching ? "magnifyingglass" : "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text(isSearching ? "Aucun article trouvé" : "Aucun article")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text(isSearching ? "Essayez une autre recherche" : "Ajoutez des flux pour commencer")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Article Row

struct ArticleRow: View {
    @Bindable var article: Article
    let isSelected: Bool
    @State private var isHovered = false
    @Environment(\.appTheme) private var theme
    @ObservedObject private var configService = ConfigService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Feed name, reading time, and date
            HStack {
                if let feed = article.feed {
                    Text(feed.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(article.readingTimeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.accentColor.opacity(0.1))
                    .clipShape(Capsule())

                Text(article.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Title
            Text(article.displayTitle)
                .font(.headline)
                .fontWeight(article.isRead ? .regular : .semibold)
                .foregroundStyle(article.isRead ? .secondary : .primary)
                .lineLimit(2)
            
            // Summary
            if !article.plainTextSummary.isEmpty {
                Text(article.plainTextSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Footer: Unread dot and star
            HStack {
                if !article.isRead {
                    Circle()
                        .fill(theme.accentColor)
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        article.isStarred.toggle()
                    }
                } label: {
                    Image(systemName: article.isStarred ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundStyle(article.isStarred ? .yellow : .secondary)
                        .scaleEffect(article.isStarred ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
                .opacity(isHovered || article.isStarred ? 1 : 0)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background {
            ZStack {
                // Glass hover effect
                if isHovered && !isSelected {
                    if !configService.config.hoverColorHex.isEmpty {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: configService.config.hoverColorHex))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.accentColor.opacity(0.15))
                    }
                }
                // Selection highlight - using theme selection color
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.selectionColor)
                }
            }
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isSelected ? theme.accentColor.opacity(0.3) : .clear, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                article.isRead = true
            }
        }
    }
}

// MARK: - Card Article Row

struct CardArticleRow: View {
    @Bindable var article: Article
    let isSelected: Bool
    @State private var isHovered = false
    @Environment(\.appTheme) private var theme
    @ObservedObject private var configService = ConfigService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Gradient header with feed icon
            HStack {
                if let feed = article.feed {
                    AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(URL(string: feed.url)?.host ?? "")&sz=64")) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fit)
                        default:
                            Image(systemName: "dot.radiowaves.up.forward")
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(
                        LinearGradient(colors: [theme.accentColor, theme.accentColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Spacer()
                
                Text(article.readingTimeText)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accentColor.opacity(0.1))
                    .clipShape(Capsule())
            }
            VStack(alignment: .leading, spacing: 8) {
                // Feed and date
                HStack {
                    if let feed = article.feed {
                        Text(feed.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(article.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // Title
                Text(article.displayTitle)
                    .font(.headline)
                    .fontWeight(article.isRead ? .regular : .bold)
                    .foregroundStyle(article.isRead ? .secondary : .primary)
                    .lineLimit(3)
                
                // Summary
                if !article.plainTextSummary.isEmpty {
                    Text(article.plainTextSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                
                // Footer
                HStack {
                    if !article.isRead {
                        Circle()
                            .fill(theme.accentColor)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(article.readingTimeText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                    
                    if article.isStarred {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.yellow)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? theme.selectionColor : Color.platformSecondaryBackground)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            
            if isHovered && !isSelected {
                 if !configService.config.hoverColorHex.isEmpty {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: configService.config.hoverColorHex))
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? theme.accentColor.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                article.isRead = true
            }
        }
    }
}

// MARK: - Compact Article Row

struct CompactArticleRow: View {
    @Bindable var article: Article
    let isSelected: Bool
    @State private var isHovered = false
    @Environment(\.appTheme) private var theme
    @ObservedObject private var configService = ConfigService.shared
    
    var body: some View {
        HStack(spacing: 10) {
            // Unread indicator
            Circle()
                .fill(article.isRead ? .clear : theme.accentColor)
                .frame(width: 6, height: 6)
            
            // Title
            Text(article.displayTitle)
                .font(.system(size: 13))
                .fontWeight(article.isRead ? .regular : .medium)
                .foregroundStyle(article.isRead ? .secondary : .primary)
                .lineLimit(1)
            
            Spacer()
            
            // Star
            if article.isStarred {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow)
            }
            
            // Source
            if let feed = article.feed {
                Text(feed.title)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .frame(maxWidth: 80, alignment: .trailing)
            }
            
            // Date
            Text(article.formattedDate)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .fill(theme.selectionColor)
            } else if isHovered {
                if !configService.config.hoverColorHex.isEmpty {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: configService.config.hoverColorHex))
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.accentColor.opacity(0.15))
                }
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                article.isRead = true
            }
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
